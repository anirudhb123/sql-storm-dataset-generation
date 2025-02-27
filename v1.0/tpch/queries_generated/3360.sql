WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_spent
    FROM 
        CustomerOrders cust
    WHERE 
        cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.total_cost,
    ps.num_suppliers,
    c.c_name AS high_value_customer,
    c.total_spent
FROM 
    PartStats ps
LEFT JOIN 
    HighValueCustomers c ON ps.num_suppliers > 5
LEFT JOIN 
    RankedSuppliers r ON r.rnk = 1 AND r.s_acctbal > 5000
WHERE 
    ps.total_cost IS NOT NULL
ORDER BY 
    ps.total_cost DESC, c.total_spent DESC;
