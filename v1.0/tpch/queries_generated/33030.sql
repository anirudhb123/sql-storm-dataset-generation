WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartSupplierMaxPrices AS (
    SELECT ps.ps_partkey, MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           COALESCE(NULLIF(m.max_supplycost, 0), p.p_retailprice) AS effective_price
    FROM part p
    LEFT JOIN PartSupplierMaxPrices m ON p.p_partkey = m.ps_partkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey
)
SELECT d.p_name, d.effective_price, COUNT(DISTINCT co.c_custkey) AS customer_count,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
       AVG(d.effective_price) OVER (PARTITION BY d.p_type) AS avg_effective_price,
       (SELECT COUNT(*) FROM nation WHERE n_regionkey = n.n_regionkey) AS nation_count
FROM PartDetails d
JOIN lineitem l ON l.l_partkey = d.p_partkey
JOIN CustomerOrderSummary co ON co.total_spent > d.effective_price
LEFT JOIN nation n ON n.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey = l.l_suppkey)
GROUP BY d.p_name, d.effective_price, n.nation_count
HAVING COUNT(DISTINCT co.c_custkey) > 5
ORDER BY d.effective_price DESC
FETCH FIRST 10 ROWS ONLY;
