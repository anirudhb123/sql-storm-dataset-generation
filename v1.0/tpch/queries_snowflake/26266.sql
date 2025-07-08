
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk,
        p.p_brand
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_acctbal, p.p_brand
),

HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_acctbal,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, c.c_phone, c.c_acctbal, c.c_mktsegment
    HAVING 
        SUM(o.o_totalprice) > 50000
)

SELECT 
    rs.s_name AS Supplier_Name,
    rs.p_brand AS Product_Brand,
    hvc.c_name AS Customer_Name,
    hvc.total_spent AS Total_Spent,
    (SELECT LISTAGG(c.c_comment, ', ') 
     FROM customer c 
     WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    ) AS Customer_Comments
FROM 
    RankedSuppliers rs
JOIN 
    HighValueCustomers hvc ON rs.p_brand IN (SELECT p.p_brand FROM part p JOIN partsupp ps ON p.p_partkey = ps.ps_partkey WHERE ps.ps_availqty > 100)
WHERE 
    rs.rnk <= 3;
