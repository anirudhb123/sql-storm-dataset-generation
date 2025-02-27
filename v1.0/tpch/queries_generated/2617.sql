WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
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
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_avail_qty,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
RecentHighSpenders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    c.c_name,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    chs.total_orders,
    chs.total_spent,
    CASE 
        WHEN chs.total_spent IS NULL THEN 'N/A'
        ELSE ROUND((chs.total_spent / NULLIF(chs.total_orders, 0)), 2) 
    END AS avg_order_value,
    COUNT(l.l_orderkey) AS total_line_items
FROM 
    RecentHighSpenders chs
LEFT JOIN 
    lineitem l ON chs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
LEFT JOIN 
    TopSuppliers ts ON ts.total_supply_cost > chs.total_spent 
GROUP BY 
    c.c_name, ts.s_name, chs.total_orders, chs.total_spent
ORDER BY 
    chs.total_spent DESC;
