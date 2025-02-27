WITH StringAggregation AS (
    SELECT 
        n.n_name AS nation,
        s.s_name AS supplier,
        STRING_AGG(CONCAT(p.p_name, ' (', p.p_brand, ')'), '; ') AS products_sold,
        COUNT(DISTINCT p.p_partkey) AS product_count,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_sales,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        n.n_name, s.s_name
)
SELECT 
    nation,
    supplier,
    products_sold,
    product_count,
    total_quantity,
    total_sales,
    last_order_date
FROM 
    StringAggregation
WHERE 
    total_sales > 50000
ORDER BY 
    total_sales DESC;