WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal = (SELECT MAX(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ts.level + 1
    FROM supplier s
    JOIN TopSuppliers ts ON s.s_acctbal < ts.s_acctbal
    WHERE ts.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
),
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT c.c_name, c.total_orders, p.p_name, ps.total_avail_qty, ps.avg_supplycost, ts.s_name AS top_supplier
FROM CustomerOrders c
JOIN PartDetails p ON c.total_orders > 0
JOIN SupplierParts ps ON p.p_partkey = ps.ps_partkey 
LEFT JOIN TopSuppliers ts ON ps.total_avail_qty > 1000
WHERE c.total_orders > (
    SELECT AVG(total_orders) FROM CustomerOrders
)
AND ps.avg_supplycost IS NOT NULL
ORDER BY c.total_orders DESC, ps.avg_supplycost ASC
LIMIT 100;
