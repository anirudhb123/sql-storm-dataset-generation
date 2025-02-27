WITH RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal > 1000
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment
    FROM RankedCustomers c
    WHERE c.rank <= 5
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    JOIN TopCustomers tc ON o.o_custkey = tc.c_custkey
),
LineItemSummary AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue, COUNT(lo.l_orderkey) AS item_count
    FROM lineitem lo
    JOIN CustomerOrders co ON lo.l_orderkey = co.o_orderkey
    GROUP BY lo.l_orderkey
)
SELECT tc.c_name, SUM(ls.revenue) AS total_revenue, COUNT(ls.item_count) AS total_items
FROM LineItemSummary ls
JOIN CustomerOrders co ON ls.l_orderkey = co.o_orderkey
JOIN TopCustomers tc ON co.o_custkey = tc.c_custkey
GROUP BY tc.c_name
ORDER BY total_revenue DESC
LIMIT 10;
