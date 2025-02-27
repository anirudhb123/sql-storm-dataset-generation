WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.nation_name, 
        rs.s_acctbal,
        rs.total_cost 
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
CustomerOrders AS (
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
),
TopCustomers AS (
    SELECT 
        co.c_custkey, 
        co.c_name, 
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > 1000
)
SELECT 
    t.c_name AS top_customer,
    t.total_spent AS amount_spent,
    h.s_name AS supplier_name,
    h.total_cost AS supplier_cost,
    h.nation_name
FROM 
    TopCustomers t
JOIN 
    HighValueSuppliers h ON h.total_cost > (SELECT AVG(total_cost) FROM HighValueSuppliers)
ORDER BY 
    t.total_spent DESC, h.total_cost ASC;
