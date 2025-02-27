WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal > 5000 AND sh.level < 3
), 
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_items,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), 
SupplierRevenue AS (
    SELECT 
        sh.s_name, 
        COALESCE(SUM(os.total_revenue), 0) AS total_revenue
    FROM 
        SupplierHierarchy sh
    LEFT JOIN 
        partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        OrderStats os ON l.l_orderkey = os.o_orderkey
    GROUP BY 
        sh.s_name
)

SELECT 
    sr.s_name,
    sr.total_revenue,
    CASE 
        WHEN sr.total_revenue > 10000 THEN 'High'
        WHEN sr.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM 
    SupplierRevenue sr
WHERE 
    sr.total_revenue IS NOT NULL
ORDER BY 
    sr.total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
