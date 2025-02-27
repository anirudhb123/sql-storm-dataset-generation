WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability of ', CAST(ps.ps_availqty AS VARCHAR), ' units.') AS supply_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        o.o_orderdate AS order_date,
        o.o_totalprice AS total_price,
        CONCAT(c.c_name, ' has placed order #', CAST(o.o_orderkey AS VARCHAR), ' on ', CAST(o.o_orderdate AS VARCHAR), ' totaling $', CAST(o.o_totalprice AS DECIMAL(15, 2)), '.') AS order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
LineItemSummary AS (
    SELECT 
        li.l_orderkey AS order_key,
        COUNT(*) AS item_count,
        SUM(li.l_extendedprice) AS total_extended_price,
        CONCAT(CAST(COUNT(*) AS VARCHAR), ' line items with total extended price of $', CAST(SUM(li.l_extendedprice) AS DECIMAL(15, 2)), ' for order #', CAST(li.l_orderkey AS VARCHAR), '.') AS line_item_info
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    sp.available_quantity,
    sp.supply_cost,
    co.customer_name,
    co.order_key,
    co.order_date,
    co.total_price,
    li.item_count,
    li.total_extended_price,
    sp.supply_info,
    co.order_info,
    li.line_item_info
FROM 
    SupplierPartDetails sp
JOIN 
    CustomerOrderDetails co ON sp.supplier_name LIKE '%' || co.customer_name || '%'
JOIN 
    LineItemSummary li ON li.order_key = co.order_key
WHERE 
    sp.available_quantity > 0
ORDER BY 
    sp.supplier_name, co.order_date DESC;
