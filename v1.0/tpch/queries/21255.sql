
WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SuppParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS cost_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    co.c_name,
    co.total_spent,
    sp.p_name,
    sp.total_cost
FROM 
    CustomerOrders co
LEFT JOIN 
    SuppParts sp ON co.c_custkey = (
        SELECT 
            o.o_custkey
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE 
            l.l_partkey = sp.p_partkey
        ORDER BY 
            o.o_orderdate DESC
        LIMIT 1
    )
WHERE 
    co.rn = 1 
    AND sp.cost_rank = 1
    AND co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
    OR (sp.total_cost IS NOT NULL AND sp.total_cost < 10000)
    OR (sp.total_cost IS NULL AND CAST(co.total_spent AS VARCHAR) LIKE '%0.00')
ORDER BY 
    co.total_spent DESC, sp.total_cost;
