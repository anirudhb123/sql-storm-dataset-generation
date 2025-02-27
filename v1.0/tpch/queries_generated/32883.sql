WITH RECURSIVE RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS rank_level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, rs.rank_level + 1
    FROM RankedSuppliers rs
    JOIN supplier s ON s.s_suppkey = rs.s_suppkey
    WHERE s.s_acctbal > 0 AND rs.rank_level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PrimaryOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY o.o_orderkey
),
SupplierParts AS (
    SELECT ps.ps_partkey, s.s_suppkey, p.p_name, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT co.c_name, COALESCE(po.total_price, 0) AS total_order_value, 
       COUNT(DISTINCT sp.s_suppkey) AS distinct_suppliers,
       JSON_AGG(DISTINCT sp.p_name) AS part_names,
       CASE 
           WHEN co.total_orders > 10 THEN 'High Value'
           WHEN co.total_orders BETWEEN 5 AND 10 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value
FROM CustomerOrders co
LEFT JOIN PrimaryOrders po ON co.c_custkey = po.o_orderkey
LEFT JOIN SupplierParts sp ON sp.ps_partkey = (
    SELECT ps_partkey FROM partsupp ps ORDER BY ps_supplycost ASC LIMIT 1 OFFSET 0
)
WHERE sp.rn = 1
GROUP BY co.c_name, po.total_price
HAVING SUM(po.total_price) IS NOT NULL
ORDER BY total_order_value DESC, customer_value;
