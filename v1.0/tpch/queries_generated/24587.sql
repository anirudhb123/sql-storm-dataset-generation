WITH RECURSIVE OrderSums AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)) AS customer_count,
    CASE 
        WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
        WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RankedSuppliers s ON l.l_suppkey = s.s_suppkey
FULL OUTER JOIN region r ON r.r_regionkey IS NOT NULL
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, supplier_name
HAVING SUM(l.l_discount) BETWEEN 0.05 AND 0.50
      AND COUNT(DISTINCT l.l_orderkey) > 10
      AND MAX(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) = 0
ORDER BY revenue DESC
LIMIT 50;
