WITH RECURSIVE supplier_rank AS (
    SELECT s_suppkey, s_name, s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) as rank
    FROM supplier
), 
nation_prices AS (
    SELECT n.n_nationkey, 
           AVG(ps.ps_supplycost * p.p_retailprice) AS avg_supply_price
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY n.n_nationkey
),
distinct_orders AS (
    SELECT DISTINCT o.o_custkey, o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'F'
),
customer_totals AS (
    SELECT c.c_custkey, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN distinct_orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT r.r_name, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       COALESCE(MAX(sp.avg_supply_price), 0) AS max_avg_supply_price,
       CASE WHEN COUNT(DISTINCT s.s_suppkey) > 0 
            THEN MAX(ct.total_spent) 
            ELSE NULL END AS highest_spender
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN nation_prices sp ON n.n_nationkey = sp.n_nationkey
LEFT JOIN customer_totals ct ON ct.c_custkey = s.s_suppkey
WHERE r.r_name NOT ILIKE '%west%'
  AND (s.s_acctbal IS NULL OR s.s_acctbal > 1000)
GROUP BY r.r_name
HAVING SUM(CASE WHEN s.s_acctbal < 1000 THEN 1 ELSE 0 END) >= 3
ORDER BY r.r_name ASC;
