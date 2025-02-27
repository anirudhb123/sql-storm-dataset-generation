WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
TopOrders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
    FROM RankedOrders ro
    WHERE ro.order_rank <= 10
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerDedupe AS (
    SELECT DISTINCT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_shipdate >= DATE '2023-01-01' AND li.l_shipdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey
)
SELECT coalesce(cds.c_name, 'Unknown') AS customer_name,
       os.o_orderkey,
       os.total_revenue,
       ss.total_supply_cost,
       os.total_revenue / NULLIF(ss.total_supply_cost, 0) AS revenue_per_cost_ratio
FROM OrderSummary os
JOIN CustomerDedupe cds ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cds.c_custkey)
JOIN SupplierStats ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem li ON ps.ps_partkey = li.l_partkey WHERE li.l_orderkey = os.o_orderkey)
ORDER BY revenue_per_cost_ratio DESC;
