WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        CONCAT(p.p_name, ' [', p.p_brand, ']') AS part_info,
        REPLACE(p.p_comment, 'assembly', 'assembly [processed]') AS modified_comment
    FROM 
        part p
), 
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        CONCAT(c.c_name, ' (', c.c_mktsegment, ')') AS customer_info,
        UPPER(SUBSTRING(c.c_comment, 1, 20)) AS short_comment
    FROM 
        customer c
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        DATE_FORMAT(o.o_orderdate, '%Y-%m') AS order_month,
        LENGTH(o.o_comment) AS comment_length
    FROM 
        orders o
)
SELECT 
    pd.part_info,
    sd.supplier_info,
    cd.customer_info,
    od.order_month,
    COUNT(od.o_orderkey) AS total_orders,
    SUM(od.o_totalprice) AS total_revenue,
    AVG(sd.comment_length) AS avg_supplier_comment_length,
    AVG(pd.comment_length) AS avg_part_comment_length,
    AVG(od.comment_length) AS avg_order_comment_length
FROM 
    PartDetails pd
JOIN 
    SupplierDetails sd ON sd.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
JOIN 
    CustomerDetails cd ON cd.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2))
JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_custkey = cd.c_custkey)
GROUP BY 
    pd.part_info, sd.supplier_info, cd.customer_info, od.order_month
ORDER BY 
    total_orders DESC, total_revenue DESC;
