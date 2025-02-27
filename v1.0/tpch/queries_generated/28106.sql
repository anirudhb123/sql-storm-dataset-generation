WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with brand ', p.p_brand) AS SupplierPartInfo
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
        o.o_totalprice,
        CONCAT('Customer ', c.c_name, ' has placed an order with total price ', o.o_totalprice) AS CustomerOrderInfo
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        CONCAT('Order ', o.o_orderkey, ' has ', COUNT(l.l_orderkey), ' line items with total revenue of ', SUM(l.l_extendedprice * (1 - l.l_discount))) AS LineItemInfo
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sp.SupplierPartInfo,
    co.CustomerOrderInfo,
    oli.LineItemInfo
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.s_suppkey = co.c_custkey
JOIN 
    OrderLineItems oli ON co.o_orderkey = oli.o_orderkey
WHERE 
    sp.p_retailprice > 100
ORDER BY 
    sp.s_name, co.o_orderkey;
