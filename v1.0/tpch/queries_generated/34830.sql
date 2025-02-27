WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal > 0
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, SUM(ps.ps_availqty) AS total_available
    FROM PartSupplier ps
    JOIN part p ON ps.p_partkey = p.p_partkey
    WHERE ps.rank <= 5
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT c.c_name AS customer_name,
       SUM(cs.total_sales) AS total_sales,
       COUNT(DISTINCT t.p_partkey) AS part_count,
       AVG(t.total_available) AS avg_availability,
       MAX(t.p_retailprice) AS max_retail_price,
       MIN(s.s_acctbal) AS min_supplier_balance
FROM CustomerSales cs
LEFT JOIN TopParts t ON t.p_partkey IN (
    SELECT ps.p_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty < 10
)
LEFT JOIN supplier s ON s.s_suppkey IN (
    SELECT DISTINCT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_supplycost < 20
)
GROUP BY c.c_name
HAVING SUM(cs.total_sales) > 5000
ORDER BY total_sales DESC
LIMIT 10;
