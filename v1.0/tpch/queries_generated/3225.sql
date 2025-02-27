WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpenders AS (
    SELECT 
        r.c_custkey,
        r.c_name,
        r.total_spent,
        r.rank,
        COALESCE(p.product_count, 0) AS product_count
    FROM 
        RankedCustomers r
    LEFT JOIN (
        SELECT 
            l.l_orderkey,
            COUNT(DISTINCT l.l_partkey) AS product_count
        FROM 
            lineitem l
        INNER JOIN 
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE 
            o.o_orderstatus = 'F' -- Only finished orders
        GROUP BY 
            l.l_orderkey
    ) p ON p.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = r.c_custkey)
    WHERE 
        r.rank <= 10
)
SELECT 
    h.c_custkey,
    h.c_name,
    h.total_spent,
    h.product_count,
    CASE 
        WHEN h.total_spent IS NULL THEN 'No Purchases'
        WHEN h.total_spent > 1000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    HighSpenders h
ORDER BY 
    h.total_spent DESC;

-- Get suppliers contributing to high-value orders along with a calculation of their offering average supply cost
SELECT 
    s.s_suppkey,
    s.s_name,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    Count(DISTINCT ps.ps_partkey) AS part_count
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_totalprice > 500 -- Only considering high-value orders
GROUP BY 
    s.s_suppkey, s.s_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 2; -- Only suppliers with more than 2 orders
