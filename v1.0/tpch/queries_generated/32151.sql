WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2
        WHERE o2.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
    )
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_supplycost, ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
),
RankedSuppliers AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS supplier_rank
    FROM part p
    JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT 
    c.c_name AS customer_name,
    SUM(COALESCE(od.l_extendedprice, 0) * (1 - COALESCE(od.l_discount, 0))) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    STRING_AGG(CONCAT(ws.p_name, ' (', ws.s_name, ')'), ', ') AS best_suppliers
FROM CustomerHierarchy ch
JOIN HighValueOrders hvo ON ch.c_custkey = hvo.o_custkey
JOIN OrderDetails od ON hvo.o_orderkey = od.o_orderkey
JOIN RankedSuppliers ws ON od.l_partkey = ws.p_partkey AND ws.supplier_rank = 1
JOIN supplier s ON ws.s_name = s.s_name
GROUP BY ch.c_name
HAVING SUM(COALESCE(od.l_extendedprice * (1 - COALESCE(od.l_discount, 0)), 0)) > 5000
ORDER BY total_revenue DESC;
