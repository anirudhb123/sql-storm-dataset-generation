WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (
            SELECT 
                AVG(c2.c_acctbal)
            FROM 
                customer c2
        )
),
SupplierPartDetails AS (
    SELECT 
        rs.s_name,
        rp.p_name,
        rp.ps_supplycost,
        HVC.c_name AS high_value_customer
    FROM 
        RankedSuppliers rs
    JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN 
        part rp ON ps.ps_partkey = rp.p_partkey
    JOIN 
        HighValueCustomers HVC ON HVC.c_custkey IN (
            SELECT o.o_custkey
            FROM orders o
            JOIN lineitem l ON o.o_orderkey = l.l_orderkey
            WHERE l.l_partkey = rp.p_partkey
        )
    WHERE 
        rs.rn = 1
)
SELECT 
    s_name,
    p_name,
    MIN(ps_supplycost) AS minimum_supply_cost,
    COUNT(DISTINCT high_value_customer) AS num_high_value_customers
FROM 
    SupplierPartDetails
GROUP BY 
    s_name, p_name
ORDER BY 
    minimum_supply_cost ASC, s_name;
