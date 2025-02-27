WITH RECURSIVE part_supply AS (
    SELECT 
        p.p_partkey, 
        SUM(ps.ps_availqty) AS total_available_qty,
        MIN(ps.ps_supplycost) AS min_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
complex_customer_order AS (
    SELECT 
        c.c_custkey,
        CASE 
            WHEN COUNT(o.o_orderkey) > 5 THEN 'Frequent'
            ELSE 'Infrequent' 
        END AS order_frequency,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    AVG(ps.total_available_qty) AS avg_available_qty,
    SUM(CASE WHEN cco.order_frequency = 'Frequent' THEN cco.total_spent ELSE 0 END) AS frequent_customer_spending,
    STRING_AGG(DISTINCT p.p_name || ' (' || p.p_container || ')', ', ') AS product_details
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    part_supply ps ON ps.p_partkey IN (SELECT p_partkey FROM partsupp ps2 WHERE ps2.ps_supplycost = ps.min_supply_cost)
LEFT JOIN 
    complex_customer_order cco ON s.s_nationkey = (SELECT n_nationkey FROM customer WHERE c_custkey = cco.c_custkey LIMIT 1)
WHERE 
    n.r_regionkey IS NOT NULL AND 
    (n.n_name IS NOT NULL OR s.s_comment IS NULL) AND 
    (s.s_acctbal BETWEEN 1000.00 AND 10000.00 OR s.s_comment LIKE '%within range%')
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    nation_name DESC
FETCH FIRST 100 ROWS ONLY;
