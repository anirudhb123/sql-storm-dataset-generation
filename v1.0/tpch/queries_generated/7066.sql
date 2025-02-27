WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.order_count,
        o.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders o ON c.c_custkey = o.c_custkey
    WHERE 
        c.c_acctbal > 50000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT h.c_custkey) AS high_value_customer_count,
    AVG(h.total_spent) AS avg_spent_per_high_value_customer,
    SUM(s.total_cost) AS total_supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
JOIN 
    HighValueCustomers h ON n.n_nationkey = h.c_nationkey
WHERE 
    rs.rank <= 3
GROUP BY 
    r.r_name
ORDER BY 
    high_value_customer_count DESC;
