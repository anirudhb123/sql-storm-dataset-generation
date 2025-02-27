WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
), SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CASE 
               WHEN s.s_acctbal IS NULL THEN 'Unknown Account'
               WHEN s.s_acctbal < 0 THEN 'Negative Balance'
               ELSE 'Valid Balance'
           END AS acct_status
    FROM supplier s
), PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           (SELECT SUM(ps1.ps_supplycost) 
            FROM partsupp ps1 
            WHERE ps1.ps_partkey = ps.ps_partkey) AS total_supplycost
    FROM partsupp ps
), CustomerStats AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
), LinesWithComments AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_discount,
           COALESCE(NULLIF(l.l_comment, ''), 'No Comment Provided') AS normalized_comment
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
), FilteredParts AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
)
SELECT DISTINCT r.r_name, SUM(so.total_spent) AS total_revenue,
       COUNT(DISTINCT so.total_orders) AS total_order_count, 
       AVG(ps.ps_supplycost) AS avg_supply_cost,
       (SELECT MAX(acct_status) FROM SupplierDetails) AS max_acct_status
FROM CustomerStats so
JOIN nation n ON so.c_nationkey = n.n_nationkey
JOIN RankedOrders ro ON ro.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM LinesWithComments l 
    WHERE l.l_discount BETWEEN 0.05 AND 0.20 
      AND l.l_suppkey IN (SELECT s.s_suppkey 
                          FROM SupplierDetails s 
                          WHERE s.acct_status = 'Valid Balance')
)
JOIN FilteredParts fp ON fp.p_partkey IN (SELECT fp2.p_partkey 
                                             FROM FilteredParts fp2 
                                             WHERE fp2.supplier_count > 10)
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY total_revenue DESC, r.r_name
LIMIT 100;
