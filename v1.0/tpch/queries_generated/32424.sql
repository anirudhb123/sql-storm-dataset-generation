WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerAggregates AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierCount AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemDetail AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, ca.total_spent,
           ROW_NUMBER() OVER (ORDER BY ca.total_spent DESC) AS rank
    FROM CustomerAggregates ca
    JOIN customer c ON ca.c_custkey = c.c_custkey
    WHERE ca.total_spent IS NOT NULL
)
SELECT p.p_name, p.p_brand, p.p_retailprice, 
       COALESCE(sc.supplier_count, 0) AS supplier_count,
       CASE 
           WHEN tc.rank <= 10 THEN 'Top 10 Customer'
           ELSE 'Regular Customer'
       END AS customer_status
FROM part p 
LEFT JOIN PartSupplierCount sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN LineItemDetail ld ON ld.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    JOIN TopCustomers tc ON o.o_custkey = tc.c_custkey
)
WHERE p.p_size > 10 
AND p.p_comment NOT LIKE '%obsolete%'
ORDER BY p.p_retailprice DESC;
