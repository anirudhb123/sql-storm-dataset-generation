WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT sup.s_suppkey, sup.s_name, sup.s_nationkey, sh.level + 1
    FROM supplier sup
    JOIN supplier_hierarchy sh ON sup.s_nationkey = sh.s_nationkey
    WHERE sup.s_acctbal > sh.level * 500
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
),
supplier_stats AS (
    SELECT n.n_nationkey, n.n_name, SUM(ps.ps_availqty) AS total_available,
           AVG(s.s_acctbal) AS avg_supplier_balance
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice,
       COALESCE(s.total_available, 0) AS total_available_parts,
       COALESCE(s.avg_supplier_balance, 0) AS avg_supplier_balance,
       sh.level AS supplier_level
FROM ranked_orders r
LEFT JOIN supplier_stats s ON s.n_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey 
                                                      FROM nation n WHERE n.n_name = 'CANADA')
WHERE r.order_rank <= 10
ORDER BY r.o_orderdate DESC, r.o_totalprice DESC;
