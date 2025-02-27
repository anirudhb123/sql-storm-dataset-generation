WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(oi.l_extendedprice * (1 - oi.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(oi.l_extendedprice * (1 - oi.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem oi ON o.o_orderkey = oi.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSegmentStats AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_mktsegment
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    r.revenue_rank,
    s.s_name,
    ss.total_supply_cost,
    cs.customer_count,
    cs.total_spent
FROM RankedOrders r
JOIN SupplierStats s ON r.total_revenue > (SELECT AVG(total_revenue) FROM RankedOrders)
JOIN CustomerSegmentStats cs ON cs.total_spent > 50000
JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = r.o_custkey)
WHERE r.revenue_rank = 1
ORDER BY r.total_revenue DESC;
