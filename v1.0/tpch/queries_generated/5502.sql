WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN (SELECT n_name FROM nation WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA'))
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
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name, 
    hs.s_name AS highest_supplier, 
    hvc.c_name AS high_value_customer, 
    psi.p_name AS part_name, 
    psi.total_avail_qty, 
    psi.avg_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    supplier hs ON rs.s_suppkey = hs.s_suppkey AND rs.rn = 1
JOIN 
    HighValueCustomers hvc ON hvc.total_spent > 50000
JOIN 
    PartSupplierInfo psi ON psi.total_avail_qty > 100
JOIN 
    nation n ON hs.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'A%'
ORDER BY 
    r.r_name, hs.s_name, hvc.total_spent DESC;
