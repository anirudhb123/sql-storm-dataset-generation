WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment,
           1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_nationkey IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment,
           sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    ROUND(AVG(o.o_totalprice), 2) AS avg_order_price,
    SUM(CASE 
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0 
        END) AS total_discounted_price,
    STRING_AGG(DISTINCT p.p_name || ' - ' || p.p_container, ', ') AS products_details,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    COALESCE(NULLIF(SUM(l.l_tax), 0), 'N/A') AS total_tax_collected,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COUNT(DISTINCT c.c_custkey) DESC) AS rank_customers
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND CURRENT_DATE
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > (SELECT AVG(cust_count) 
                                        FROM (SELECT n2.n_nationkey, COUNT(DISTINCT c2.c_custkey) AS cust_count
                                              FROM nation n2 
                                              LEFT JOIN customer c2 ON n2.n_nationkey = c2.c_nationkey 
                                              GROUP BY n2.n_nationkey) AS subquery)
ORDER BY total_customers DESC, avg_order_price DESC;
