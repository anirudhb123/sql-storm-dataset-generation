WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
TopPartSupplies AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey) AS total_supplycost
    FROM partsupp ps
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_retailprice, 
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returned_quantity,
    (SELECT COUNT(DISTINCT o.o_orderkey)
     FROM orders o 
     JOIN customer c ON o.o_custkey = c.c_custkey
     WHERE c.c_nationkey = n.n_nationkey AND o.o_orderstatus = 'O') AS active_orders,
    COALESCE((SELECT MAX(ps_availqty) 
              FROM TopPartSupplies tps 
              WHERE tps.ps_partkey = p.p_partkey), 0) AS max_supply_quantity,
    (SELECT CONCAT('Supplier: ', s.s_name, ' | Balance: ', CAST(s.s_acctbal AS VARCHAR))
     FROM RankedSuppliers s 
     WHERE s.rnk = 1 AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM TopPartSupplies ps WHERE ps.ps_partkey = p.p_partkey)
     LIMIT 1) AS top_supplier_info
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN nation n ON n.n_nationkey = (SELECT n2.n_nationkey FROM nation n2 
                                    WHERE n2.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA') 
                                    LIMIT 1)
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, n.n_nationkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00
ORDER BY p.p_partkey ASC, total_returned_quantity DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
