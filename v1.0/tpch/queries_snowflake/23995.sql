
WITH RankedSales AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierStats AS (
    SELECT
        ps.ps_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        RANK() OVER (ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS part_count_rank
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT
    r.r_name,
    COALESCE(SUM(CASE WHEN ss.unique_parts IS NOT NULL THEN ss.unique_parts ELSE 0 END), 0) AS total_unique_parts,
    COALESCE(SUM(cs.total_orders), 0) AS total_orders_per_region,
    AVG(cs.total_spent) AS avg_spent_per_customer,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ts.total_sales) AS median_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.ps_suppkey
LEFT JOIN CustomerOrders cs ON s.s_nationkey = cs.c_custkey
LEFT JOIN RankedSales ts ON ts.l_orderkey = cs.total_orders
LEFT JOIN part p ON ss.unique_parts = p.p_partkey
WHERE 
    r.r_comment IS NOT NULL OR
    (s.s_acctbal > 1000 AND s.s_comment LIKE '%reliable%')
GROUP BY r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY r.r_name DESC;
