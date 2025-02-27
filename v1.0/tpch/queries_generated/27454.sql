WITH RankedSuppliers AS (
    SELECT 
        s_name,
        s_nationkey,
        s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rnk
    FROM 
        supplier
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value,
        MAX(p.p_name) AS part_name
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
    HAVING 
        total_value > 10000
),
CustomerOrders AS (
    SELECT 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    r.r_name AS region_name,
    hs.s_name AS highest_acct_supplier,
    p.part_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    RankedSuppliers hs
JOIN 
    nation n ON hs.s_nationkey = n.n_nationkey
JOIN 
    HighValueParts p ON p.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = hs.s_suppkey)
JOIN 
    CustomerOrders co ON co.total_spent > 5000
WHERE 
    hs.rnk = 1
ORDER BY 
    region_name, total_spent DESC;
