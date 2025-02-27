
WITH RECURSIVE order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        os.total_sales,
        os.sales_rank
    FROM 
        order_summary os
    JOIN 
        orders o ON os.o_orderkey = o.o_orderkey
    WHERE 
        os.sales_rank <= 10
),
supplier_part AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_availability
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT tp.o_orderkey) AS num_orders,
    COALESCE(SUM(sp.total_availability), 0) AS total_avail_qty
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    top_orders tp ON l.l_orderkey = tp.o_orderkey
LEFT JOIN 
    supplier_part sp ON p.p_partkey = sp.ps_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT tp.o_orderkey) > 5 AND 
    COALESCE(SUM(sp.total_availability), 0) > 100
ORDER BY 
    total_avail_qty DESC, num_orders DESC;
