WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank,
        p.p_name,
        p.p_brand,
        p.p_retailprice
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    p.p_retailprice,
    COALESCE(c.total_spent, 0) AS customer_total_spent,
    CASE 
        WHEN s.rank = 1 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_category,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    RankedSuppliers s
JOIN 
    part p ON s.p_partkey = p.p_partkey 
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighSpendingCustomers c ON c.c_custkey = o.o_custkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    s.s_name, p.p_name, p.p_retailprice, c.total_spent, s.rank
ORDER BY 
    supplier_name, part_name;
