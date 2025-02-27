WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_type, 
           ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
    HAVING total_value > 10000
)
SELECT ns.n_name AS nation, 
       COUNT(DISTINCT hvo.o_orderkey) AS high_value_orders,
       AVG(p.p_retailprice) AS avg_retail_price,
       SUM(COALESCE(sh.s_acctbal, 0)) AS total_supplier_balance
FROM nation ns
LEFT JOIN customer c ON ns.n_nationkey = c.c_nationkey
LEFT JOIN HighValueOrders hvo ON c.c_custkey = hvo.o_custkey
LEFT JOIN PartDetails p ON hvo.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey IN (
        SELECT p_partkey FROM part WHERE p_type LIKE 'TYPE%'
    )
)
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
GROUP BY ns.n_name
ORDER BY high_value_orders DESC, avg_retail_price DESC;
