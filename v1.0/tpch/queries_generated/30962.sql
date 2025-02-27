WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_type, p_retailprice, 0 AS level
    FROM part
    WHERE p_size < 10
    
    UNION ALL
    
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey + 1
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
RelevantOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           SUM(l.l_quantity) OVER (PARTITION BY o.o_orderkey) AS total_quantity,
           COUNT(*) OVER (PARTITION BY o.o_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
),
OuterJoinResults AS (
    SELECT c.c_name, r.r_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN RelevantOrders o ON c.c_custkey = o.o_orderkey
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY c.c_name, r.r_name
)
SELECT ph.p_name,
       ph.p_brand,
       sd.s_name AS best_supplier,
       COALESCE(orr.total_spent, 0) AS customer_spending,
       ph.p_retailprice * (1 - AVG(l.l_discount) OVER (PARTITION BY ph.p_partkey)) AS adjusted_price
FROM PartHierarchy ph
LEFT JOIN SupplierDetails sd ON ph.p_partkey = sd.s_suppkey
LEFT JOIN OuterJoinResults orr ON sd.s_name = orr.c_name
LEFT JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
WHERE ph.level = 0
AND (ph.p_retailprice > 100 OR ph.p_name LIKE '%special%')
ORDER BY adjusted_price DESC, customer_spending DESC;
