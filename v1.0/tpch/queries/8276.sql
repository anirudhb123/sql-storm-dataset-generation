WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierRegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(co.total_spent) AS total_spent_by_customers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    sr.region_name, 
    sr.total_suppliers, 
    sr.total_customers, 
    sr.total_spent_by_customers, 
    rs.supply_rank, 
    rs.s_suppkey, 
    rs.s_name
FROM 
    SupplierRegionStats sr
JOIN 
    RankedSuppliers rs ON sr.region_name = (SELECT r.r_name FROM region r WHERE r.r_regionkey IN (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey IN (SELECT s.s_nationkey FROM supplier s WHERE rs.s_suppkey = s.s_suppkey)))
WHERE 
    rs.supply_rank <= 5
ORDER BY 
    sr.total_spent_by_customers DESC, 
    rs.total_supply_cost DESC;
