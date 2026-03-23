# app/services/eligibility.py

import pandas as pd


def is_eligible_for_ajo(transactions, contribution_amount):
    if not transactions:
        return False

    df = pd.DataFrame(transactions)

    # Ensure proper types
    df["date"] = pd.to_datetime(df["date"])
    df["month"] = df["date"].dt.to_period("M")

    # Separate credits and debits
    df["credit"] = df.apply(
        lambda x: x["amount"] if x["type"] == "credit" else 0, axis=1
    )
    df["debit"] = df.apply(
        lambda x: x["amount"] if x["type"] == "debit" else 0, axis=1
    )

    # ---- Monthly aggregation ----
    monthly = df.groupby("month").agg({
        "credit": "sum",
        "debit": "sum"
    })

    monthly["surplus"] = monthly["credit"] - monthly["debit"]

    # ---- Require at least 3 months ----
    if len(monthly) < 3:
        return False

    last_3_surplus = monthly["surplus"].tail(3)
    median_surplus = last_3_surplus.median()

    threshold = 3 * contribution_amount

    return median_surplus >= threshold