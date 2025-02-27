WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS num_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.ps_availqty, 0) AS available_quantity,
    COALESCE(ps.ps_supplycost, 0) AS supply_cost,
    CASE 
        WHEN ps.ps_supplycost IS NULL OR ps.ps_supplycost <= 0 THEN 'Not available'
        ELSE 'Available'
    END AS availability_status,
    STRING_AGG(DISTINCT n.n_name, ', ') WITHIN GROUP (ORDER BY n.n_name) AS nations_supplied,
    STRING_AGG(DISTINCT c.c_name, ', ') FILTER (WHERE cs.total_spent > 1000) AS high_value_customers,
    MAX(ws.total_spent) OVER (PARTITION BY p.p_partkey) AS max_spent,
    SUM(NULLIF(o.o_totalprice, 0)) OVER () AS total_all_orders
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    CustomerSpend cs ON cs.c_custkey = (
        SELECT c.c_custkey FROM customer c ORDER BY c.c_acctbal DESC LIMIT 1
    )
LEFT JOIN 
    (SELECT DISTINCT c.c_custkey, cs.total_spent FROM customer c JOIN CustomerSpend cs ON c.c_custkey = cs.c_custkey) ws 
    ON ws.c_custkey = cs.c_custkey
GROUP BY 
    p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
ORDER BY 
    p.p_partkey DESC
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1 OR SUM(ps.ps_availqty) IS NULL
LIMIT 100;
