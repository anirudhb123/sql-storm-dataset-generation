WITH RECURSIVE CTE_Sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    
    UNION ALL

    SELECT 
        cs.c_custkey,
        cs.c_name,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_sales
    FROM 
        CTE_Sales cs
    JOIN 
        lineitem lo ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = lo.l_orderkey)
    GROUP BY 
        cs.c_custkey, cs.c_name
),
RegionSupplier AS (
    SELECT 
        r.r_name,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_name
)
SELECT 
    r.r_name,
    COALESCE(s.s_name, 'No Suppliers') AS supplier_name,
    s.total_cost,
    c.c_name,
    SUM(cs.total_sales) AS total_sales,
    AVG(cs.total_sales) OVER (PARTITION BY r.r_name) AS avg_sales_per_region
FROM 
    RegionSupplier s
FULL OUTER JOIN 
    nation n ON s.s_name IS NULL AND n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = 'null')
LEFT JOIN 
    CTE_Sales cs ON s.s_name = (SELECT s2.s_name FROM supplier s2 JOIN partsupp ps ON s2.s_suppkey = ps.ps_suppkey WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10))
JOIN 
    region r ON r.r_name = s.r_name
GROUP BY 
    r.r_name, s.s_name, c.c_name
HAVING 
    SUM(cs.total_sales) > 1000
ORDER BY 
    r.r_name, total_cost DESC, total_sales DESC;
