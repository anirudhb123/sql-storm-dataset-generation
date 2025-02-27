WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 10000
),
CustomerOrderStats AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment <> 'AUTOMOBILE'
    GROUP BY c.c_custkey
),
PartSales AS (
    SELECT p.p_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY p.p_partkey
)
SELECT ps.p_partkey,
       ps.total_sales,
       cs.order_count,
       cs.total_spent,
       rs.s_name AS top_supplier
FROM PartSales ps
LEFT JOIN CustomerOrderStats cs ON ps.p_partkey = cs.c_custkey
LEFT JOIN RankedSuppliers rs ON ps.p_partkey = rs.s_suppkey
WHERE ps.total_sales > (SELECT AVG(total_sales) FROM PartSales) 
  AND rs.rn = 1
  AND COALESCE(cs.total_spent, 0) > 5000
ORDER BY ps.total_sales DESC, cs.order_count ASC
LIMIT 50
UNION
SELECT NULL AS p_partkey,
       NULL AS total_sales,
       cs.order_count,
       cs.total_spent,
       'N/A' AS top_supplier
FROM CustomerOrderStats cs
WHERE cs.order_count > 10
ORDER BY cs.total_spent DESC;
