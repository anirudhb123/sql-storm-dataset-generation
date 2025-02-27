WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(ls.total_revenue, 0) AS total_revenue,
    ss.total_supply_cost,
    r.price_rank
FROM RankedOrders r
LEFT JOIN LineItemSummary ls ON r.o_orderkey = ls.l_orderkey
FULL OUTER JOIN SupplierSummary ss ON ss.total_supply_cost > 10000
WHERE r.price_rank <= 10 OR ss.total_supply_cost IS NOT NULL
ORDER BY r.o_orderdate, ss.total_supply_cost DESC;
