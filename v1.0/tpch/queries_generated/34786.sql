WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 1 AS level
    FROM part
    WHERE p_size IS NOT NULL
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice, ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON p.p_partkey = ph.p_partkey
    WHERE ph.level < 5
),
customer_summary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_region AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
),
frequent_customers AS (
    SELECT 
        cs.c_custkey, 
        cs.c_name,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM customer_summary cs
    WHERE cs.total_spent IS NOT NULL
),
final_summary AS (
    SELECT 
        ph.p_partkey,
        ph.p_name,
        ph.p_retailprice,
        sr.r_name,
        fc.c_name,
        fc.rank
    FROM part_hierarchy ph
    LEFT JOIN supplier_region sr ON sr.total_supply_cost > (SELECT AVG(total_supply_cost) FROM supplier_region)
    LEFT JOIN frequent_customers fc ON fc.c_custkey = (SELECT o.o_custkey FROM orders o ORDER BY o.o_orderdate DESC LIMIT 1)
)
SELECT 
    p.p_name,
    p.p_retailprice,
    s.r_name,
    c.c_name,
    CASE 
        WHEN c.c_name IS NULL THEN 'No Purchases'
        ELSE 'Purchased'
    END AS purchase_status
FROM final_summary p
FULL OUTER JOIN supplier_region s ON p.p_partkey = s.s_suppkey
FULL OUTER JOIN frequent_customers c ON p.p_partkey = c.c_custkey
WHERE (s.total_supply_cost IS NULL OR p.p_retailprice > 50)
ORDER BY p.p_name, s.r_name, c.rank DESC
LIMIT 100;
