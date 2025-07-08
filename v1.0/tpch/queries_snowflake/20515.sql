
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, NULL AS parent_s_suppkey
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
), 
FilteredLineItems AS (
    SELECT l.*, 
           COALESCE(l.l_discount, 0) AS effective_discount,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS rn
    FROM lineitem l
    WHERE l.l_quantity > 1 AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
),
NationRegions AS (
    SELECT n.n_nationkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, r.r_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
    UNION
    SELECT n.n_nationkey, r.r_name, SUM(s.s_acctbal) AS total_account_balance
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, r.r_name
    HAVING SUM(s.s_acctbal) < 1000000
)
SELECT p.p_name, 
       SUM(COALESCE(l.l_extendedprice * (1 - l.effective_discount), 0)) AS total_price,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(COALESCE(o.o_totalprice, 0)) AS avg_order_total,
       MAX(r.r_name) AS region_name
FROM part p
JOIN FilteredLineItems l ON p.p_partkey = l.l_partkey
JOIN orders o ON o.o_orderkey = l.l_orderkey
JOIN customer c ON c.c_custkey = o.o_custkey
RIGHT JOIN NationRegions nr ON c.c_nationkey = nr.n_nationkey
LEFT JOIN region r ON nr.r_name = r.r_name
WHERE p.p_size IN (SELECT DISTINCT ps.ps_partkey 
                   FROM partsupp ps 
                   WHERE ps.ps_availqty >= ALL (SELECT ps2.ps_availqty 
                                                FROM partsupp ps2 
                                                WHERE ps2.ps_partkey = ps.ps_partkey))
GROUP BY p.p_name
HAVING COUNT(DISTINCT l.l_orderkey) > 1 
   OR EXISTS (SELECT 1 
               FROM SupplierHierarchy sh 
               WHERE sh.parent_s_suppkey IS NULL)
ORDER BY total_price DESC;
