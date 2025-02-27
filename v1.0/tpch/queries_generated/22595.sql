WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT sh.s_suppkey, sh.s_name, sh.s_nationkey, sh.s_acctbal * 0.9, 
           ROW_NUMBER() OVER (PARTITION BY sh.s_nationkey ORDER BY sh.s_acctbal * 0.9 DESC)
    FROM supplier_hierarchy sh
    WHERE sh.rank > 1
),
nation_details AS (
    SELECT n.n_nationkey, n.n_name, n.n_comment, 
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost,
           COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name, n.n_comment
),
top_nations AS (
    SELECT n.n_name, nd.total_supply_cost, nd.total_customers,
           RANK() OVER (ORDER BY nd.total_supply_cost DESC NULLS LAST) AS supply_rank
    FROM nation_details nd
    JOIN nation n ON nd.n_nationkey = n.n_nationkey
    WHERE nd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM nation_details)
)
SELECT sh.supp_name, sh.supp_acctbal, tn.n_name, tn.total_supply_cost
FROM supplier_hierarchy sh
JOIN top_nations tn ON sh.s_nationkey = tn.n_nationkey
WHERE tn.supply_rank <= 5 
  AND sh.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier 
                      WHERE s_acctbal IS NOT NULL AND s_suppkey <> sh.s_suppkey)
ORDER BY tn.total_supply_cost DESC, sh.supp_acctbal ASC NULLS LAST;
