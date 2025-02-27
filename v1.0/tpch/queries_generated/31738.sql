WITH RECURSIVE SupplyChain AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT c_custkey, c_name, c_acctbal, c_mktsegment,
           COUNT(DISTINCT o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    GROUP BY c_custkey, c_name, c_acctbal, c_mktsegment
),
PartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           p.p_name, p.p_retailprice, s.s_name, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS cheapest_supplier
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_discounted_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),
CustomerAnalysis AS (
    SELECT c.c_custkey, c.c_name, c.mktsegment, 
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.mktsegment
)
SELECT c.c_name, ca.mktsegment, ca.total_spent, ca.avg_order_value,
       s.s_name AS supplier_name, p.p_name, p.ps_availqty,
       COALESCE(ranked.rank, 0) AS supplier_rank
FROM CustomerAnalysis ca
JOIN HighValueCustomers c ON ca.c_custkey = c.c_custkey
JOIN PartSuppliers p ON p.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0)
LEFT JOIN SupplyChain s ON s.s_suppkey = p.ps_suppkey
LEFT JOIN RankedOrders ranked ON ranked.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
WHERE ca.total_spent > 1000
ORDER BY ca.total_spent DESC, supplier_rank;
