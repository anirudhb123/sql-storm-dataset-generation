WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 1 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
CustomerOrderSummary AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT rh.r_name,
       cs.c_name,
       cs.total_spent,
       p.p_name,
       psd.total_available,
       psd.avg_supply_cost,
       ROW_NUMBER() OVER (PARTITION BY rh.r_name ORDER BY cs.total_spent DESC) AS rank
FROM RegionHierarchy rh
JOIN CustomerOrderSummary cs ON cs.c_custkey IN (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < CURRENT_DATE()
)
LEFT JOIN lineitem l ON l.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'O'
)
JOIN PartSupplierDetails psd ON l.l_partkey = psd.p_partkey
WHERE psd.total_available > 100
AND cs.total_spent IS NOT NULL
ORDER BY rh.r_name, cs.total_spent DESC;
