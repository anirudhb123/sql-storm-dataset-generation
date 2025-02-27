WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
FilteredCustomers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)
SELECT 
    fc.c_name,
    fc.c_acctbal,
    rs.s_name,
    rs.total_supply_cost
FROM 
    FilteredCustomers fc
JOIN 
    RankedSuppliers rs ON fc.nation_name = (SELECT n_name FROM nation WHERE n_nationkey = rs.s_nationkey)
WHERE 
    rs.rank <= 3
ORDER BY 
    fc.c_acctbal DESC, rs.total_supply_cost DESC;
