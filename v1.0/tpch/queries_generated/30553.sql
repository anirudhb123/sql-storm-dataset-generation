WITH RECURSIVE subquery AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
    UNION ALL
    SELECT 
        c.c_custkey,
        c.c_name,
        s.total_spent * 1.1 AS total_spent
    FROM 
        customer c
    JOIN 
        subquery s ON c.c_custkey = s.c_custkey
    WHERE 
        c.c_acctbal < 500
),
ranked_customers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        subquery cs
)
SELECT 
    pc.p_name,
    ps.ps_supplycost,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    rc.c_name AS top_customer,
    rc.total_spent
FROM 
    part pc
LEFT JOIN 
    partsupp ps ON pc.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    ranked_customers rc ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = rc.c_custkey)
WHERE 
    ps.ps_availqty IS NOT NULL
GROUP BY 
    pc.p_name, ps.ps_supplycost, rc.c_name, rc.total_spent
HAVING 
    total_quantity > 0 AND rc.rank <= 10
ORDER BY 
    rc.rank, total_quantity DESC
LIMIT 20;
