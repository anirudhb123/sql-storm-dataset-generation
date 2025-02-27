
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey, n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    rs.s_name,
    rs.total_supply_cost,
    COALESCE(co.total_orders, 0) AS total_orders,
    CASE 
        WHEN rs.rank <= 3 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_type
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.n_nationkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
WHERE 
    r.r_name LIKE '%America%'
ORDER BY 
    rs.total_supply_cost DESC, r.r_name, rs.s_name;
