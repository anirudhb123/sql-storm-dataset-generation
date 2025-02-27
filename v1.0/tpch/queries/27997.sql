WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        CONCAT(s.s_name, ' - ', p.p_name) AS combined_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        CONCAT(c.c_name, ' - Order ', o.o_orderkey) AS order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_orderkey) AS item_count,
        STRING_AGG(DISTINCT CONCAT(l.l_partkey, '; ', l.l_quantity), ', ') AS line_item_details
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sp.s_name,
    sp.p_name,
    sp.short_comment,
    co.c_name,
    co.order_info,
    od.total_value,
    od.item_count,
    od.line_item_details
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.s_suppkey = co.c_custkey  
JOIN 
    OrderDetails od ON co.o_orderkey = od.o_orderkey
WHERE 
    sp.combined_name LIKE '%part%' AND
    od.total_value > 1000
ORDER BY 
    od.total_value DESC, 
    sp.s_name;