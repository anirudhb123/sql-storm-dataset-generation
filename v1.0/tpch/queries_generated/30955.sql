WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, NULL::integer AS parent_suppkey
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.parent_suppkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT cs.c_name, cs.order_count, cs.total_spent,
       ps.p_name, ps.total_avail, ps.avg_supply_cost,
       sh.s_name, sh.s_acctbal
FROM CustomerOrderSummary cs
FULL OUTER JOIN PartSupplierSummary ps ON cs.order_count > 0 
                                    AND ps.total_avail IS NOT NULL
LEFT JOIN SupplierHierarchy sh ON cs.total_spent > 1000 
WHERE cs.last_order_date >= '2022-01-01' 
AND (ps.avg_supply_cost < 500 OR ps.total_avail IS NULL)
ORDER BY cs.total_spent DESC, ps.avg_supply_cost ASC;
