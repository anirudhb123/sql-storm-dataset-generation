
WITH RankedSales AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        COALESCE(supplier_count.supplier_count, 0) AS supplier_count
    FROM 
        orders o
    LEFT JOIN (
        SELECT 
            o.o_orderkey, 
            COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        JOIN 
            partsupp ps ON l.l_partkey = ps.ps_partkey
        GROUP BY 
            o.o_orderkey
    ) supplier_count ON o.o_orderkey = supplier_count.o_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_order_value,
    ARRAY_AGG(DISTINCT p.p_brand) AS unique_brands,
    AVG(CASE WHEN o.o_orderdate IS NULL THEN 0 ELSE EXTRACT(YEAR FROM o.o_orderdate) END) AS avg_year_of_orders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN 
    HighValueOrders o ON c.c_custkey = o.o_orderkey
WHERE 
    p.p_container IS NOT NULL AND 
    p.p_size BETWEEN 1 AND 10 AND 
    p.p_retailprice IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(o.o_totalprice) > 10000
ORDER BY 
    customer_count DESC, 
    r.r_name;
