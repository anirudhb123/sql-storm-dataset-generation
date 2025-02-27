WITH Filters AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_retailprice > 50.00 
        AND LENGTH(p.p_name) > 10
        AND TRIM(s.s_name) LIKE 'A%'
        AND c.c_mktsegment = 'BUILDING'
),
Aggregated AS (
    SELECT 
        f.p_brand, 
        f.p_type,
        COUNT(*) AS order_count,
        SUM(f.o_totalprice) AS total_revenue,
        AVG(f.p_retailprice) AS avg_retail_price
    FROM 
        Filters f
    GROUP BY 
        f.p_brand, 
        f.p_type
)
SELECT 
    a.p_brand,
    a.p_type,
    a.order_count,
    a.total_revenue,
    a.avg_retail_price,
    CONCAT('Total Revenue: $', FORMAT(a.total_revenue, 2)) AS formatted_revenue,
    CONCAT('Average Price: $', FORMAT(a.avg_retail_price, 2)) AS formatted_avg_price
FROM 
    Aggregated a
WHERE 
    a.order_count > 5
ORDER BY 
    a.total_revenue DESC;
