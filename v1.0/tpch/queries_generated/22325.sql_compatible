
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 3
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_account_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.ps_availqty,
    COALESCE(d.total_revenue, 0) AS total_revenue,
    ns.supplier_count,
    ns.total_account_balance,
    CASE 
        WHEN ns.supplier_count IS NULL THEN 'No Suppliers'
        WHEN ns.total_account_balance > 1000 THEN 'High Balance'
        ELSE 'Low Balance'
    END AS balance_category
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN OrderStats d ON d.o_orderkey = ps.ps_suppkey
LEFT JOIN NationStats ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE 
    ps.ps_availqty > (
        SELECT AVG(ps2.ps_availqty) FROM partsupp ps2 WHERE ps2.ps_supplycost < (SELECT AVG(ps3.ps_supplycost) FROM partsupp ps3)
    )
AND p.p_retailprice BETWEEN 10 AND 100
ORDER BY balance_category DESC, p.p_name ASC
LIMIT 50 OFFSET 5;
