WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 50.00
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rs.s_name AS Supplier_Name,
    rs.s_acctbal AS Supplier_Account_Balance,
    hvc.c_name AS Customer_Name,
    hvc.c_acctbal AS Customer_Account_Balance,
    od.total_revenue AS Order_Revenue
FROM 
    RankedSuppliers rs
JOIN 
    HighValueCustomers hvc ON rs.rn = 1
JOIN 
    OrderDetails od ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type = (SELECT p_type FROM part p WHERE p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey LIMIT 1))))
ORDER BY 
    rs.s_acctbal DESC, hvc.c_acctbal DESC;
