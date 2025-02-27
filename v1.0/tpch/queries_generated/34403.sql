WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as rnk
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderLineDetails AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.o_orderkey, l.l_partkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(o.total_revenue, 0) AS total_revenue,
    COALESCE(o.line_count, 0) AS line_count,
    COALESCE(ss.total_avail_qty, 0) AS total_avail_qty,
    ss.avg_supply_cost,
    RANK() OVER (ORDER BY COALESCE(o.total_revenue, 0) DESC) AS revenue_rank
FROM CustomerOrders co
LEFT JOIN OrderLineDetails o ON co.o_orderkey = o.o_orderkey
LEFT JOIN SupplierStats ss ON o.l_partkey IN (
    SELECT ps_partkey 
    FROM partsupp 
    WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_name LIKE '%Supplier%')
)
WHERE co.rnk = 1
ORDER BY revenue_rank
LIMIT 100;
