WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate > oh.o_orderdate
),
SupplierStats AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_availqty) AS total_availqty, 
           AVG(ps.ps_supplycost) AS avg_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
CombinedData AS (
    SELECT ch.o_orderkey, ch.o_custkey, ch.o_totalprice, co.order_count, 
           co.total_spent, ss.total_availqty, ss.avg_supplycost, ss.supplier_count
    FROM OrderHierarchy ch
    JOIN CustomerOrders co ON ch.o_custkey = co.c_custkey
    LEFT JOIN SupplierStats ss ON ss.ps_partkey = (SELECT ps_partkey 
                                                    FROM lineitem 
                                                    WHERE l_orderkey = ch.o_orderkey 
                                                    ORDER BY l_linenumber LIMIT 1)
)
SELECT 
    cd.o_orderkey,
    cd.o_custkey,
    cd.order_count,
    cd.total_spent,
    COALESCE(cd.total_availqty, 0) AS safe_total_availqty,
    CASE 
        WHEN cd.order_count > 0 THEN ROUND(cd.total_spent / cd.order_count, 2)
        ELSE NULL 
    END AS avg_spent_per_order,
    cd.avg_supplycost,
    cd.supplier_count
FROM CombinedData cd
WHERE cd.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY cd.o_totalprice DESC
LIMIT 100;
