WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerSegment AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
RegionNational AS (
    SELECT n.n_name, r.r_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    r.r_name, 
    n.n_name, 
    s.s_name,
    COALESCE(ci.order_count, 0) AS customer_orders,
    si.total_supply_value,
    os.net_revenue,
    CASE 
        WHEN os.net_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Present'
    END AS revenue_status
FROM RegionNational rn
LEFT JOIN SupplierInfo si ON rn.n_name = si.s_nationkey
LEFT JOIN CustomerSegment ci ON si.s_nationkey = ci.c_mktsegment
LEFT JOIN OrderStats os ON ci.order_count = os.o_orderkey
WHERE si.total_supply_value > 1000
ORDER BY rn.r_name, n.n_name, si.total_supply_value DESC;
