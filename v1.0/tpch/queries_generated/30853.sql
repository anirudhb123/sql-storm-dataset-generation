WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
    WHERE sh.level < 5
),
CustomerTotal AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierCount AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_comment, p.p_size, 
           COALESCE(psc.supplier_count, 0) AS supplier_count
    FROM part p
    LEFT JOIN PartSupplierCount psc ON p.p_partkey = psc.ps_partkey
    WHERE p.p_retailprice > 100.00 AND p.p_size BETWEEN 10 AND 20
),
OrderLineAnalysis AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_quantity, l.l_discount, l.l_tax,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM orders o
    INNER JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)

SELECT cust.c_name AS customer_name,
       ROUND(cust.total_spent, 2) AS total_spent,
       part.p_name AS part_name,
       part.p_retailprice AS retail_price,
       part.supplier_count AS total_suppliers,
       CASE
           WHEN ol.rn = 1 THEN 'Top Line Item'
           ELSE 'Regular Line Item'
       END AS item_priority
FROM CustomerTotal cust
INNER JOIN HighValueParts part ON cust.total_spent > 5000
LEFT JOIN OrderLineAnalysis ol ON ol.l_partkey = part.p_partkey
WHERE cust.c_name IS NOT NULL
ORDER BY cust.total_spent DESC, part.p_retailprice ASC
LIMIT 100;
