
WITH RECURSIVE cte_supplier_sales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey 
    GROUP BY 
        s.s_suppkey, s.s_name
),
total_sales AS (
    SELECT 
        SUM(total_sales) AS overall_sales
    FROM 
        cte_supplier_sales
),
nation_details AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    COALESCE(ss.total_sales, 0) AS supplier_total_sales,
    ns.supplier_count,
    ns.avg_acctbal,
    (SELECT overall_sales FROM total_sales) AS TPC_H_total_sales
FROM 
    nation n
LEFT JOIN 
    cte_supplier_sales ss ON n.n_nationkey = (SELECT n_regionkey FROM nation WHERE n.n_name = ss.s_name)
JOIN 
    nation_details ns ON n.n_name = ns.n_name
WHERE 
    ns.avg_acctbal > (SELECT AVG(c.c_acctbal) FROM customer c WHERE c.c_mktsegment = 'BUILDING')
ORDER BY 
    supplier_total_sales DESC, n.n_name;
