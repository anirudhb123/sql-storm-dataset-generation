WITH RegionalStats AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count, 
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_quantity) > (SELECT AVG(total_sold) FROM (
        SELECT SUM(l2.l_quantity) AS total_sold
        FROM lineitem l2
        GROUP BY l2.l_partkey
    ) AS avg_sales)
),
LowStockSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) < 50
)
SELECT 
    r.region_name, 
    pp.p_name, 
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY r.region_name ORDER BY revenue DESC) AS revenue_rank,
    COALESCE(s.s_name, 'N/A') AS supplier_name,
    CASE 
        WHEN pp.total_sold IS NOT NULL THEN pp.total_sold 
        ELSE 0 
    END AS popular_part_sales
FROM RegionalStats r
JOIN PopularParts pp ON r.nation_count > 1
LEFT JOIN LowStockSuppliers s ON s.s_suppkey = pp.p_partkey
JOIN lineitem l ON pp.p_partkey = l.l_partkey
WHERE l.l_shipdate >= DATE '2023-01-01'
    AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY r.region_name, pp.p_name, s.s_name
ORDER BY r.region_name, revenue DESC
FETCH FIRST 100 ROWS ONLY;
