
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank_by_spending
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
NationStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(ss.total_supply_value) AS total_supply_value
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.total_suppliers,
    ns.total_supply_value,
    cs.c_name AS top_customer,
    cs.total_orders,
    cs.total_spent
FROM 
    NationStats ns
LEFT JOIN 
    (SELECT DISTINCT c.c_name, c.c_nationkey, co.total_orders, co.total_spent 
     FROM CustomerOrders co 
     JOIN customer c ON co.c_custkey = c.c_custkey) cs ON ns.n_name = (
        SELECT n.n_name 
        FROM nation n 
        WHERE n.n_nationkey = cs.c_nationkey
    )
WHERE 
    ns.total_suppliers > 0
ORDER BY 
    ns.total_supply_value DESC, 
    cs.total_spent DESC
LIMIT 10;
