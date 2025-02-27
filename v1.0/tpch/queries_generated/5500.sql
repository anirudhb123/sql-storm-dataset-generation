WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
),

HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)

SELECT 
    r.r_name AS region,
    rs.s_name AS supplier_name,
    rs.total_supply_cost,
    hvc.c_name AS high_value_customer,
    hvc.total_spent,
    hvc.total_orders
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON n.n_nationkey = (SELECT n_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.total_spent > 5000
WHERE 
    rs.rank <= 5
ORDER BY 
    r.r_name, rs.total_supply_cost DESC, hvc.total_spent DESC;
