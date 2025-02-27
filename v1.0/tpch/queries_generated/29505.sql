WITH part_supplier_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability of ', CAST(ps.ps_availqty AS varchar), ' units at a cost of ', CAST(ps.ps_supplycost AS varchar), ' each.') AS supplier_part_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CONCAT(c.c_name, ' placed an order with order key ', CAST(o.o_orderkey AS varchar), ' for a total price of ', CAST(o.o_totalprice AS varchar), ' on ', CAST(o.o_orderdate AS varchar), '.') AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        CONCAT('Total value for order ', CAST(l.l_orderkey AS varchar), ' after discount is ', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS varchar), '.') AS lineitem_summary_info
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    psd.supplier_part_info,
    co.customer_order_info,
    ls.lineitem_summary_info
FROM 
    part_supplier_details psd
JOIN 
    customer_orders co ON psd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey IN (SELECT l_orderkey FROM lineitem_summary))
JOIN 
    lineitem_summary ls ON co.o_orderkey = ls.l_orderkey
ORDER BY 
    co.o_orderdate DESC;
