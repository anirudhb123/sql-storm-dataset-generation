
WITH recursive_supplier_sales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        s.s_suppkey, s.s_name
),
filtered_nations AS (
    SELECT 
        n.n_name, 
        n.n_nationkey, 
        CASE 
            WHEN n.n_name LIKE '%land%' THEN 'landed'
            ELSE 'not landed'
        END AS land_status
    FROM 
        nation n
    WHERE 
        n.n_comment IS NOT NULL
),
order_info AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice,
        (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = o.o_orderkey AND l.l_shipmode = 'AIR') AS air_items_count
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
)
SELECT 
    fs.s_name, 
    fn.n_name AS nation_name, 
    os.o_orderstatus, 
    COALESCE(SUM(fs.total_sales), 0) AS total_sales, 
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    (SELECT COUNT(*) FROM order_info oi WHERE oi.o_orderstatus = 'O' AND oi.o_totalprice > 1000) AS high_value_orders_count
FROM 
    filtered_nations fn
LEFT JOIN 
    recursive_supplier_sales fs ON fs.s_suppkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = fs.s_suppkey LIMIT 1)
LEFT JOIN 
    order_info os ON os.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_linenumber = 1 LIMIT 1)
WHERE 
    fs.total_sales > (SELECT AVG(total_sales) FROM recursive_supplier_sales)
GROUP BY 
    fs.s_name, fn.n_name, os.o_orderstatus
HAVING 
    COUNT(DISTINCT os.o_orderkey) > 1
ORDER BY 
    total_sales DESC;
