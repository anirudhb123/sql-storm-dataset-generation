
WITH RECURSIVE CustomerCTE AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, cc.level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_custkey = cc.c_custkey
    WHERE cc.level < 5
), 
PartValue AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
HighValueParts AS (
    SELECT p.p_partkey, pv.total_value
    FROM part p
    JOIN PartValue pv ON p.p_partkey = pv.p_partkey
    WHERE pv.total_value > (SELECT AVG(total_value) FROM PartValue)
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT ps.ps_partkey) >= (SELECT COUNT(*) FROM HighValueParts) / 5
)

SELECT c.c_name, 
       COALESCE(s.s_name, 'No Supplier') AS supplier_name,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS return_qty,
       SUM(CASE WHEN l.l_returnflag = 'N' THEN l.l_quantity ELSE 0 END) AS non_return_qty,
       RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice) DESC) AS customer_rank
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierInfo s ON s.s_suppkey = l.l_suppkey
WHERE c.c_acctbal IN (SELECT DISTINCT c_acctbal FROM customer WHERE c.c_acctbal IS NOT NULL)
AND EXISTS (SELECT 1 FROM HighValueParts hp WHERE hp.p_partkey = l.l_partkey)
GROUP BY c.c_custkey, c.c_name, s.s_name
ORDER BY customer_rank, c.c_name DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM customer c1 WHERE c1.c_acctbal > 0) / 10;
