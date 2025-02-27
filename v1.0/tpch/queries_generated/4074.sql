WITH regional_sales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        r.r_name, n.n_name
),
high_value_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
top_products AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS product_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT 
    r.nation_name,
    r.region_name,
    r.total_sales,
    s.s_name AS supplier_name,
    tp.p_name AS product_name,
    tp.product_sales
FROM 
    regional_sales r
FULL OUTER JOIN 
    high_value_suppliers s ON r.nation_name = CASE WHEN r.nation_name IS NOT NULL THEN s.s_name ELSE NULL END
FULL OUTER JOIN 
    top_products tp ON r.total_sales IS NOT NULL AND tp.rank <= 10
WHERE 
    (s.s_name IS NOT NULL OR tp.product_sales IS NOT NULL)
ORDER BY 
    r.region_name, r.total_sales DESC, tp.product_sales DESC;
