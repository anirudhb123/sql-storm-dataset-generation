WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.s_name, 'N/A') AS supplier_name,
    hvp.total_supply_cost,
    co.total_spent,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No orders'
        ELSE 'Has orders'
    END AS order_status
FROM 
    part p
LEFT JOIN 
    HighValueParts hvp ON p.p_partkey = hvp.ps_partkey
LEFT JOIN 
    RankedSuppliers r ON r.rnk = 1 AND r.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey
    )
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    p.p_partkey;
