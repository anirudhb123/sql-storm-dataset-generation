WITH RECURSIVE SupplyCosts AS (
    SELECT ps_partkey, 
           SUM(ps_supplycost * ps_availqty) AS total_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS rn
    FROM partsupp
    GROUP BY ps_partkey
    HAVING SUM(ps_supplycost) > 100.00
),
HighValueOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate > '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000.00
),
SupplierDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           COUNT(DISTINCT p.p_partkey) AS part_count,
           MAX(s.s_acctbal) AS max_balance,
           AVG(s.s_acctbal) AS avg_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.r_name,
       COALESCE(SUM(s.max_balance), 0) AS total_max_balance,
       AVG(ld.total_value) OVER() AS average_order_value,
       COUNT(DISTINCT s.part_count) AS unique_part_count,
       STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
       (SELECT COUNT(DISTINCT o.o_orderkey) 
        FROM HighValueOrders o 
        WHERE o.o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE
        AND EXISTS (SELECT 1 
                    FROM region r2 
                    JOIN nation n ON r2.r_regionkey = n.n_regionkey 
                    WHERE n.n_nationkey = s.s_nationkey
                    AND r2.r_name LIKE 'R%')
            ) AS high_value_orders_count
FROM region r
LEFT JOIN SupplierDetails s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                              FROM partsupp ps 
                                              WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                      FROM part p 
                                                                      WHERE p.p_size BETWEEN 10 AND 20)
                                              LIMIT 1) 
LEFT JOIN HighValueOrders ld ON ld.o_orderkey = s.s_suppkey
GROUP BY r.r_name
HAVING SUM(s.max_balance) IS NOT NULL
ORDER BY r.r_name DESC;
