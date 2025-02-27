WITH RecursivePartCount AS (
    SELECT p_partkey, COUNT(*) AS total_count
    FROM part
    GROUP BY p_partkey
    HAVING COUNT(*) > 1
), RankedSuppliers AS (
    SELECT s_supkey, s_name, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rn
    FROM supplier
), OrderSummary AS (
    SELECT o_custkey, SUM(o_totalprice) AS total_spent,
           COUNT(o_orderkey) AS total_orders,
           MAX(o_orderdate) AS last_order_date
    FROM orders
    GROUP BY o_custkey
    HAVING SUM(o_totalprice) > 10000
), FilteredLines AS (
    SELECT l_orderkey, AVG(l_extendedprice * (1 - l_discount)) AS avg_price,
           COUNT(CASE WHEN l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem
    WHERE l_shipdate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY l_orderkey
)
SELECT p.p_name, s.s_name, p.p_retailprice, cs.total_spent, r.r_name,
       COALESCE(MAX(rn), 0) AS rank, 
       CASE 
           WHEN cs.total_spent IS NULL THEN 'NO ORDERS'
           ELSE CAST(cs.total_spent / 2 AS DECIMAL(12, 2))
       END AS half_spent,
       (SELECT COUNT(DISTINCT ps_partkey) 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 100 AND ps.ps_supplycost < p.p_retailprice) AS supplier_count
FROM part p
LEFT JOIN RecursivePartCount rpc ON p.p_partkey = rpc.p_partkey
LEFT JOIN RankedSuppliers s ON s.s_supkey = (SELECT TOP 1 ps.ps_suppkey 
                                              FROM partsupp ps 
                                              WHERE ps.ps_partkey = p.p_partkey 
                                              ORDER BY ps.ps_supplycost ASC)
LEFT JOIN OrderSummary cs ON cs.o_custkey = (SELECT TOP 1 o.o_custkey 
                                              FROM orders o 
                                              WHERE o.o_orderkey = (SELECT TOP 1 l.l_orderkey 
                                                                    FROM lineitem l 
                                                                    WHERE l.l_partkey = p.p_partkey 
                                                                    ORDER BY l.l_extendedprice DESC))
LEFT JOIN nation n ON n.n_nationkey = (SELECT MAX(s.n_nationkey) 
                                        FROM supplier s 
                                        WHERE s.s_supkey = s.s_supkey)
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE (p.p_size > 10 AND p.p_size < 100 OR p.p_brand LIKE 'B%')
  AND (s.s_acctbal IS NULL OR s.s_acctbal > 50000)
GROUP BY p.p_name, s.s_name, p.p_retailprice, cs.total_spent, r.r_name
HAVING avg_price > 100 AND return_count < 5
ORDER BY p.p_comment DESC NULLS LAST, hs.half_spent DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
