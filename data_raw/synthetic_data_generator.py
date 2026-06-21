"""
Synthetic data generator — Gaming Compliance & Risk Intelligence Platform
=========================================================================

Generates SYNTHETIC, gaming-realistic data for the platform. Nothing here is real:
all transactions, players, market figures, and labels are fabricated with a fixed
seed and clearly labelled as synthetic. The project is an independent portfolio
exercise and is not affiliated with, endorsed by, or representative of any
regulator, gaming authority, or operator, and uses no proprietary or internal data.

Two datasets are produced:

1. AML transactions  -> data_raw/transactions_synthetic.csv
   IBM "Transactions for AML"-style schema (From/To accounts, amounts, laundering
   label) with player-wallet semantics: deposits/withdrawals via electronic payment
   methods. Injected typologies give the AML rules ground truth.

2. Market / GGR       -> data_raw/market_monthly_synthetic.csv
                      -> data_raw/market_by_product_synthetic.csv
   A fabricated monthly online-gaming market series (wagers, GGR, active accounts,
   ARPPA) and a product-category breakdown. Figures are illustrative only and do
   not correspond to any real market.

Run:  python data_raw/synthetic_data_generator.py   (deterministic, fixed seed)
"""

import numpy as np
import pandas as pd

RNG = np.random.default_rng(42)
START = pd.Timestamp("2024-04-01")
END = pd.Timestamp("2024-06-30 23:59:59")

BANKS = [f"Bank_{i:02d}" for i in range(1, 13)]
METHODS = ["Interac e-Transfer", "Credit Card", "Debit Card", "Crypto",
           "Prepaid Card", "Bank Transfer"]
HIGH_RISK_METHODS = ["Crypto", "Prepaid Card"]   # elevated ML risk (rule R06)
N_PLAYERS = 300

COLUMNS = ["Timestamp", "From_Bank", "From_Account", "To_Bank", "To_Account",
           "Amount_Paid", "Payment_Currency", "Amount_Received", "Receiving_Currency",
           "Payment_Format", "Transaction_Type", "Is_Laundering"]


def _rand_ts(n):
    span = int((END - START).total_seconds())
    return [START + pd.Timedelta(seconds=int(s)) for s in RNG.integers(0, span, size=n)]


def main():
    accounts = [f"ACC-{1000 + i}" for i in range(N_PLAYERS)]
    external = [f"EXT-{9000 + i}" for i in range(40)]
    rows = []

    def add(ts, player, amt, method, ttype, laundering, counterparty=None):
        cp = counterparty if counterparty is not None else RNG.choice(external)
        ccy = "CAD"
        rows.append([ts, RNG.choice(BANKS), player, RNG.choice(BANKS), cp,
                     float(amt), ccy, float(amt), ccy, method, ttype, int(laundering)])

    # ---- 1. Normal activity (legitimate deposits & withdrawals) --------------
    n_normal = 5000
    amounts = np.clip(np.round(RNG.lognormal(5.5, 1.0, n_normal), 2), 5, 9000)
    ts = _rand_ts(n_normal)
    for i in range(n_normal):
        ttype = RNG.choice(["Deposit", "Withdrawal"], p=[0.6, 0.4])
        add(ts[i], RNG.choice(accounts), amounts[i], RNG.choice(METHODS), ttype, 0)

    # ---- 2. Large transactions (laundering) ----------------------------------
    ts = _rand_ts(45)
    for i in range(45):
        add(ts[i], RNG.choice(accounts), round(RNG.uniform(10000, 50000), 2),
            RNG.choice(["Crypto", "Bank Transfer"]), "Withdrawal", 1)

    # ---- 3. Structuring / smurfing (laundering) ------------------------------
    for acct in RNG.choice(accounts, size=30, replace=False):
        base = START + pd.Timedelta(days=int(RNG.integers(0, 80)))
        for _ in range(int(RNG.integers(3, 7))):
            t = base + pd.Timedelta(hours=int(RNG.integers(0, 72)))
            add(t, acct, round(RNG.uniform(9000, 9900), 2),
                RNG.choice(["Interac e-Transfer", "Credit Card"]), "Deposit", 1)

    # ---- 4. Rapid movement of funds (laundering) -----------------------------
    for acct in RNG.choice(accounts, size=30, replace=False):
        t0 = START + pd.Timedelta(days=int(RNG.integers(0, 80)), hours=int(RNG.integers(0, 20)))
        amt = round(RNG.uniform(2000, 15000), 2)
        add(t0, acct, amt, RNG.choice(["Credit Card", "Interac e-Transfer"]), "Deposit", 1)
        t1 = t0 + pd.Timedelta(hours=int(RNG.integers(1, 6)))
        add(t1, acct, round(amt * RNG.uniform(0.9, 0.99), 2), "Crypto", "Withdrawal", 1)

    # ---- 5. High transaction velocity (laundering) ---------------------------
    for acct in RNG.choice(accounts, size=8, replace=False):
        t0 = START + pd.Timedelta(days=int(RNG.integers(0, 80)), hours=int(RNG.integers(0, 16)))
        for _ in range(int(RNG.integers(8, 13))):
            t = t0 + pd.Timedelta(minutes=int(RNG.integers(0, 240)))
            add(t, acct, round(RNG.uniform(500, 3000), 2),
                RNG.choice(["Credit Card", "Debit Card"]), "Deposit", 1)

    # ---- 6. Round-number large transactions (laundering) ---------------------
    ts = _rand_ts(15)
    for i in range(15):
        add(ts[i], RNG.choice(accounts), float(int(RNG.integers(10, 50)) * 1000),
            RNG.choice(["Crypto", "Bank Transfer"]), "Withdrawal", 1)

    # ---- 7. Counterparty concentration (laundering) --------------------------
    for acct in RNG.choice(accounts, size=8, replace=False):
        payee = RNG.choice(external)
        base = START + pd.Timedelta(days=int(RNG.integers(0, 70)))
        for _ in range(int(RNG.integers(4, 7))):
            t = base + pd.Timedelta(days=int(RNG.integers(0, 25)))
            add(t, acct, round(RNG.uniform(4000, 7000), 2), "Bank Transfer",
                "Withdrawal", 1, counterparty=payee)

    # ---- 7b. Dormant account reactivation (laundering) -----------------------
    # Dedicated accounts (outside the active pool): one early small deposit, then a
    # large withdrawal after a 30+ day gap. Caught by rule R08.
    for acct in [f"ACC-{2000 + i}" for i in range(6)]:
        t0 = START + pd.Timedelta(days=int(RNG.integers(0, 5)))
        add(t0, acct, round(RNG.uniform(50, 500), 2), RNG.choice(METHODS), "Deposit", 0)
        t1 = t0 + pd.Timedelta(days=int(RNG.integers(35, 70)))
        add(t1, acct, round(RNG.uniform(5000, 15000), 2),
            RNG.choice(["Crypto", "Bank Transfer"]), "Withdrawal", 1)

    # ---- 8. Sanctions / watchlist hits (laundering) --------------------------
    # A handful of accounts matched against a sanctions/watchlist; any activity is
    # reportable. Caught by rule R11.
    sanctioned = list(RNG.choice(accounts, size=5, replace=False))
    for acct in sanctioned:
        for _ in range(int(RNG.integers(2, 5))):
            t = START + pd.Timedelta(days=int(RNG.integers(0, 85)))
            add(t, acct, round(RNG.uniform(1000, 20000), 2),
                RNG.choice(METHODS), RNG.choice(["Deposit", "Withdrawal"]), 1)

    df = pd.DataFrame(rows, columns=COLUMNS)

    # ---- Politically Exposed Persons (PEP) — elevates risk, not an alert ------
    # PEP status raises customer risk rating but is not itself suspicious.
    pep = list(RNG.choice([a for a in accounts if a not in sanctioned], size=12, replace=False))
    df["PEP_Flag"] = df.From_Account.isin(pep).astype(int)
    df["Sanctions_Flag"] = df.From_Account.isin(sanctioned).astype(int)
    df.loc[df.Sanctions_Flag == 1, "Is_Laundering"] = 1  # sanctions hits are reportable

    df = df.sort_values("Timestamp").reset_index(drop=True)
    df["Timestamp"] = df["Timestamp"].dt.strftime("%Y-%m-%d %H:%M:%S")

    out_path = "data_raw/transactions_synthetic.csv"
    df.to_csv(out_path, index=False)
    print(f"Wrote {len(df):,} rows to {out_path}")
    print(f"Laundering rate: {df['Is_Laundering'].mean():.2%}")
    print(f"PEP accounts: {len(pep)} | Sanctioned accounts: {len(sanctioned)}")
    print(f"Sanctioned transactions: {int(df.Sanctions_Flag.sum())}")


def generate_market():
    """Fabricated monthly online-gaming market series + product breakdown.

    SYNTHETIC and illustrative only — the figures do not correspond to any real
    market, operator, or regulator. A smooth growth curve with seasonal wobble and
    noise gives the GGR-reporting layer realistic-looking trends to chart.
    """
    rng = np.random.default_rng(2024)
    n = 48  # 48 synthetic months
    months = pd.date_range("2022-04-01", periods=n, freq="MS")

    # smooth S-curve growth for cash wagers ($M), with seasonality + noise
    t = np.arange(n)
    base = 600 + 1400 / (1 + np.exp(-(t - 20) / 7.0))          # ~600 -> ~2000
    season = 1 + 0.06 * np.sin(2 * np.pi * (months.month - 1) / 12)
    cash_wagers = np.round(base * season * rng.normal(1.0, 0.04, n), 0)

    ggr_rate = np.clip(rng.normal(0.039, 0.003, n), 0.032, 0.046)  # GGR ~3.2-4.6% of wagers
    naggr = np.round(cash_wagers * ggr_rate, 1)
    active_k = np.round(180 + 6.5 * t + rng.normal(0, 8, n), 0)     # active accounts (000s)
    arppa = np.round(naggr * 1000 / active_k, 0)                    # GGR per active account

    fyq = [f"FY{((m.year + (1 if m.month >= 4 else 0)) % 100):02d}Q{((m.month - 4) % 12) // 3 + 1}"
           for m in months]
    market = pd.DataFrame({
        "FiscalYearQuarter": fyq,
        "YearMonth": months.strftime("%Y-%m"),
        "CashWagers_M": cash_wagers.astype(int),
        "NAGGR_M": naggr,
        "ActiveAccounts_K": active_k.astype(int),
        "ARPPA": arppa.astype(int),
    })
    market.to_csv("data_raw/market_monthly_synthetic.csv", index=False)

    # product-category split (synthetic shares that drift over time)
    products = {"CASINO": 0.66, "SPORTS": 0.28, "POKER": 0.06}
    prows = []
    for i, m in enumerate(months):
        drift = 0.04 * np.sin(2 * np.pi * i / 18)
        shares = {"CASINO": products["CASINO"] + drift,
                  "SPORTS": products["SPORTS"] - drift * 0.7,
                  "POKER": products["POKER"] - drift * 0.3}
        tot = sum(shares.values())
        for prod, sh in shares.items():
            w_share = round(sh / tot, 2)
            g_share = round(min(0.9, max(0.02, w_share + rng.normal(0, 0.03))), 2)
            prows.append({
                "YearMonth": m.strftime("%Y-%m"),
                "ProductCategory": prod,
                "CashWagers_M": int(round(market.CashWagers_M[i] * w_share)),
                "NAGGR_M": round(float(market.NAGGR_M[i]) * g_share, 1),
                "WagerShare": w_share,
                "GGRShare": g_share,
            })
    pd.DataFrame(prows).to_csv("data_raw/market_by_product_synthetic.csv", index=False)
    print(f"Wrote {n} months to data_raw/market_monthly_synthetic.csv")
    print(f"Wrote {len(prows)} rows to data_raw/market_by_product_synthetic.csv")


if __name__ == "__main__":
    main()
    generate_market()
