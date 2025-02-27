WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00 AND 
        p.p_size BETWEEN 5 AND 20
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
)
SELECT 
    rs.s_name AS supplier_name,
    fp.p_name AS part_name,
    fp.short_comment,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    RankedSuppliers rs
JOIN 
    partsupp ps ON rs.s_suppkey = ps.ps_suppkey
JOIN 
    FilteredParts fp ON ps.ps_partkey = fp.p_partkey
JOIN 
    CustomerOrders co ON co.total_spent > 1000.00
WHERE 
    rs.rnk = 1
ORDER BY 
    co.order_count DESC, co.total_spent DESC;
