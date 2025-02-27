WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_orders,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY COALESCE(SUM(o.o_totalprice), 0) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name AS customer_name,
    c.total_orders AS total_spent,
    s.s_name AS supplier_name,
    ss.total_supply_cost AS supplier_total_cost,
    CASE 
        WHEN ss.total_supply_cost IS NULL THEN 'No Cost'
        ELSE 'Cost Effective' 
    END AS cost_effectiveness,
    AVG(l.l_extendedprice) OVER (PARTITION BY c.c_custkey) AS avg_item_price,
    COALESCE(i.o_order_status, 'No Orders') AS order_status
FROM 
    CustomerOrders c
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    SupplierStats ss ON l.l_suppkey = ss.s_suppkey
LEFT JOIN 
    (SELECT o.o_orderkey, o.o_orderstatus FROM orders o WHERE o.o_orderstatus IS NOT NULL) i ON i.o_orderkey = l.l_orderkey
WHERE 
    c.order_rank <= 5
ORDER BY 
    total_spent DESC, customer_name ASC;
