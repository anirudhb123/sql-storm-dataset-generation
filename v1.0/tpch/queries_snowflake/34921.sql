
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        sh.level + 1
    FROM 
        SupplierHierarchy sh
    JOIN 
        supplier s ON s.s_nationkey = sh.s_nationkey
    WHERE 
        sh.level < 5
),
LineItemStats AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(*) AS total_orders,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < DATE '1998-10-01'
    GROUP BY 
        l.l_suppkey
),
OrderStats AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_revenue,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_custkey
)
SELECT 
    n.n_name,
    SUM(ss.total_sales) AS total_sales_by_nation,
    COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
    AVG(os.total_revenue) AS avg_revenue_per_customer
FROM 
    nation n
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    (SELECT s.s_suppkey, COALESCE(ls.total_sales, 0) AS total_sales
     FROM supplier s 
     LEFT JOIN LineItemStats ls ON s.s_suppkey = ls.l_suppkey
    ) ss ON ss.s_suppkey = s.s_suppkey
LEFT JOIN 
    OrderStats os ON os.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
ORDER BY 
    total_sales_by_nation DESC;
