WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUBSTRING(s.s_comment, 1, 20) AS short_comment,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
ValidParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_size, 
        p.p_retailprice, 
        REPLACE(p.p_comment, 'obsolete', 'available') AS available_comment
    FROM 
        part p 
    WHERE 
        p.p_size BETWEEN 10 AND 30
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
)

SELECT 
    rs.s_name AS Supplier_Name,
    rs.short_comment AS Supplier_Comment,
    vp.p_name AS Part_Name,
    vp.p_retailprice AS Retail_Price,
    co.c_name AS Customer_Name,
    co.total_spent AS Total_Spent
FROM 
    RankedSuppliers rs
JOIN 
    partsupp ps ON rs.s_suppkey = ps.ps_suppkey
JOIN 
    ValidParts vp ON ps.ps_partkey = vp.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    CustomerOrders co ON l.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey LIMIT 1)
WHERE 
    rs.rnk <= 5 AND 
    co.total_spent > 500
ORDER BY 
    Total_Spent DESC, 
    Supplier_Name;
