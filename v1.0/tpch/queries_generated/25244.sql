WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with quantity ', CAST(ps.ps_availqty AS CHAR), ' at a cost of $', FORMAT(ps.ps_supplycost, 2)) AS supply_details
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
        o.o_totalprice AS total_price,
        CONCAT('Order ', o.o_orderkey, ' by ', c.c_name, ' totaling $', FORMAT(o.o_totalprice, 2)) AS order_summary
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey AS order_key,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count,
        CONCAT('Order ', l.l_orderkey, ' has ', COUNT(*) , ' items totaling revenue of $', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS revenue_summary
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    s.supplier_name,
    p.part_name,
    c.customer_name,
    o.order_key,
    li.total_revenue,
    li.item_count,
    s.supply_details,
    c.order_summary,
    li.revenue_summary
FROM 
    SupplierPartDetails s
JOIN 
    CustomerOrderDetails c ON s.available_quantity > 0 
JOIN 
    LineItemDetails li ON li.order_key = c.order_key
WHERE 
    s.supply_cost < 100
ORDER BY 
    s.supplier_name, c.customer_name, li.total_revenue DESC;
