WITH RECURSIVE SupplierRank AS (
    SELECT s_suppkey, s_name, s_acctbal, RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
), AvailableParts AS (
    SELECT ps.partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    WHERE ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY ps.partkey
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, COUNT(DISTINCT l.l_linenumber) AS item_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
      AND l.l_shipdate IS NOT NULL
    GROUP BY o.o_orderkey, o.o_custkey
), NationSupplier AS (
    SELECT n.n_name, s.s_name, COUNT(DISTINCT l.l_orderkey) AS orders_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY n.n_name, s.s_name
), FinalSummary AS (
    SELECT 
        p.p_partkey, p.p_name, p.p_retailprice,
        COALESCE(NULLIF(a.total_available, 0), 1) AS available_parts,
        ns.orders_count,
        sr.s_name,
        CASE 
            WHEN ns.orders_count IS NULL THEN 'No Orders'
            ELSE 'Orders Exist' 
        END AS order_status
    FROM part p
    LEFT JOIN AvailableParts a ON p.p_partkey = a.partkey
    LEFT JOIN NationSupplier ns ON ns.n_name = (SELECT r_name FROM region r WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT TOP 1 c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderstatus = 'F') ) ))) LIMIT 1)
    LEFT JOIN SupplierRank sr ON sr.rank = 1
)
SELECT p_partkey, p_name, p_retailprice, available_parts, orders_count, s_name, order_status
FROM FinalSummary
WHERE p_size BETWEEN 10 AND 20 
  AND p_comment NOT LIKE '%fragile%'
ORDER BY p_retailprice DESC
FETCH FIRST 100 ROWS ONLY;
