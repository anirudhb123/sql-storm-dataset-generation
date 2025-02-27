WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
), 
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey 
    HAVING 
        total_value > 10000
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 500
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        total_orders > 5
) 
SELECT 
    ns.r_name,
    COUNT(DISTINCT c.c_custkey) AS number_of_high_value_customers,
    SUM(hl.total_value) AS total_high_value_parts,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
FROM 
    RankedSuppliers rs
JOIN 
    nation nw ON rs.s_nationkey = nw.n_nationkey
JOIN 
    CustomerOrderSummary c ON c.c_custkey IN (
        SELECT c2.c_custkey 
        FROM CustomerOrderSummary c2 
        WHERE c2.total_spent > 1000
    )
JOIN 
    HighValueParts hl ON hl.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_supplycost < 100
    )
JOIN 
    region ns ON nw.n_regionkey = ns.r_regionkey 
GROUP BY 
    ns.r_name
ORDER BY 
    number_of_high_value_customers DESC, total_high_value_parts DESC;
