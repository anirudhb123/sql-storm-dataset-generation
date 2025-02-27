WITH supplier_part_info AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name, 
        ps.ps_availqty AS available_quantity, 
        ps.ps_supplycost AS supply_cost, 
        s.s_comment AS supplier_comment 
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
customer_order_info AS (
    SELECT 
        c.c_name AS customer_name, 
        o.o_orderkey AS order_key, 
        o.o_orderstatus AS order_status, 
        o.o_totalprice AS total_price, 
        o.o_orderdate AS order_date 
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
lineitem_info AS (
    SELECT 
        l.l_orderkey AS order_key, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price 
    FROM 
        lineitem l 
    GROUP BY 
        l.l_orderkey
)
SELECT 
    spi.supplier_name, 
    spi.part_name, 
    clo.customer_name, 
    clo.order_key, 
    clo.order_status, 
    clo.total_price, 
    clo.order_date, 
    li.total_lineitem_price, 
    spi.available_quantity, 
    spi.supply_cost, 
    spi.supplier_comment 
FROM 
    supplier_part_info spi 
JOIN 
    customer_order_info clo ON spi.supplier_name LIKE '%' || SUBSTRING(clo.customer_name FROM 1 FOR 3) || '%' 
JOIN 
    lineitem_info li ON clo.order_key = li.order_key 
WHERE 
    spi.available_quantity > 100 AND 
    clo.order_date > CURRENT_DATE - INTERVAL '1 year' 
ORDER BY 
    clo.total_price DESC, spi.supply_cost ASC 
LIMIT 50;
