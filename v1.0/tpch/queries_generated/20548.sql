WITH RECURSIVE price_cte AS (
    SELECT ps_partkey, MIN(ps_supplycost) AS min_supplycost
    FROM partsupp
    GROUP BY ps_partkey
),
customer_spend AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'O') AND o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey
),
high_spend_customers AS (
    SELECT c.c_custkey
    FROM customer_spend c
    WHERE c.total_spent > (
        SELECT AVG(total_spent) FROM customer_spend
    )
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, 
           COALESCE(SUM(ps.ps_availqty * (p.p_retailprice / NULLIF(ps.ps_supplycost, 0))), 0) AS value_ratio,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
supplier_info AS (
    SELECT DISTINCT s.s_nationkey, s.s_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE l.l_shipdate < CURRENT_DATE
    GROUP BY s.s_nationkey, s.s_name
)
SELECT DISTINCT r.r_name AS region_name, np.n_name AS nation_name, 
                SUM(ps.value_ratio) AS total_value_ratio,
                (SELECT COUNT(*) FROM high_spend_customers) AS high_spender_count,
                GROUP_CONCAT(DISTINCT si.s_name ORDER BY si.total_sales DESC) AS supplier_names
FROM region r
LEFT JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN part_supplier ps ON np.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey IS NOT NULL LIMIT 1)
LEFT JOIN supplier_info si ON si.s_nationkey = np.n_nationkey
WHERE ps.value_ratio IS NOT NULL AND ps.rn = 1
GROUP BY r.r_name, np.n_name
HAVING total_value_ratio > (
    SELECT AVG(total_value_ratio) FROM part_supplier
    )
ORDER BY total_value_ratio DESC;
