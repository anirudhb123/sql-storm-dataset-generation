WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        *
    FROM 
        RankedSuppliers
    WHERE 
        rn <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    T1.s_name AS Top_Supplier_Name,
    T2.order_count,
    T2.total_spent,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 'No Orders'
        ELSE CAST(SUM(l.l_quantity) AS VARCHAR)
    END AS total_quantity_sold
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers T1 ON ps.ps_suppkey = T1.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    CustomerOrders T2 ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = T2.c_custkey)
GROUP BY 
    p.p_name, p.p_brand, p.p_type, T1.s_name, T2.order_count, T2.total_spent
HAVING 
    SUM(l.l_discount) > 0.1 OR COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 
    total_spent DESC,
    total_quantity_sold DESC NULLS LAST;
