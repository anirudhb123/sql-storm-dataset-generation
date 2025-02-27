WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS region_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopRegions AS (
    SELECT 
        r.r_name,
        SUM(rs.total_supply_value) AS total_region_supply
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.region_rank
    WHERE 
        rs.region_rank <= 3
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cr.c_name,
    tr.r_name,
    cr.total_order_value,
    tr.total_region_supply
FROM 
    CustomerOrders cr
JOIN 
    TopRegions tr ON cr.c_custkey = (SELECT TOP 1 c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'NATION_NAME') ORDER BY total_order_value DESC)
ORDER BY 
    cr.total_order_value DESC, tr.total_region_supply DESC;
