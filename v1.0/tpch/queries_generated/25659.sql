WITH part_supplier AS (
    SELECT 
        p.p_name, 
        s.s_name, 
        ps.ps_supplycost, 
        ps.ps_availqty, 
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Cost: ', ps.ps_supplycost, ', Available Quantity: ', ps.ps_availqty) AS supplier_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), customer_order_status AS (
    SELECT 
        c.c_name, 
        o.o_orderstatus, 
        CONCAT('Customer: ', c.c_name, ', Order Status: ', o.o_orderstatus) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), sales_summary AS (
    SELECT 
        ps.p_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        CONCAT('PartKey: ', ps.p_partkey, ', Total Sales: ', SUM(l.l_extendedprice * (1 - l.l_discount))) AS sales_info
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.p_partkey
)
SELECT 
    p_name, 
    supplier_info, 
    customer_order_info, 
    sales_info 
FROM 
    part_supplier ps  
FULL OUTER JOIN 
    customer_order_status co ON ps.p_name LIKE '%' || SUBSTRING(co.customer_order_info FROM 10 FOR 25) || '%'
FULL OUTER JOIN 
    sales_summary ss ON ps.p_partkey = ss.p_partkey
WHERE 
    ps.ps_availqty > 100 
    OR co.o_orderstatus = 'O' 
    OR ss.total_sales > 10000
ORDER BY 
    p_name, co.o_orderstatus, ss.total_sales DESC;
