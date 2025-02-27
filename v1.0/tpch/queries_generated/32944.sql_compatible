
WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_retailprice, p_comment, 1 AS level
    FROM part
    WHERE p_size > (SELECT AVG(p_size) FROM part)
    
    UNION ALL
    
    SELECT p.p_partkey, p.p_name, p.p_retailprice, CONCAT(ph.p_comment, ' -> ', p.p_name), ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey - 1
    WHERE ph.level < 5
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS supply_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
AggregatedData AS (
    SELECT ph.p_partkey, ph.p_name, ph.p_retailprice, cp.total_spent, sp.supply_count,
           ROW_NUMBER() OVER (PARTITION BY ph.p_partkey ORDER BY ph.p_retailprice DESC) AS rank
    FROM PartHierarchy ph
    FULL OUTER JOIN CustomerOrderDetails cp ON ph.p_partkey = cp.c_custkey
    FULL OUTER JOIN SupplierPartDetails sp ON ph.p_partkey = sp.s_suppkey
    WHERE (cp.total_spent IS NOT NULL AND sp.supply_count IS NOT NULL)
      OR (cp.total_spent IS NULL AND sp.supply_count IS NULL)
)
SELECT *
FROM AggregatedData
WHERE rank <= 10
ORDER BY p_retailprice DESC, total_spent ASC;
