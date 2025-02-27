WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
SupplierNationDetails AS (
    SELECT 
        r.r_name,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT s.s_suppkey) AS suppliers,
    SUM(hl.total_spent) AS total_spent_by_high_value_customers,
    AVG(rs.total_supply_cost) AS avg_supply_cost
FROM 
    SupplierNationDetails s_n
JOIN 
    HighValueCustomers hl ON s_n.n_name = hl.c_name
JOIN 
    RankedSuppliers rs ON s_n.n_name = rs.n_name
JOIN 
    nation n ON s_n.n_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    avg_supply_cost DESC, total_spent_by_high_value_customers DESC;
