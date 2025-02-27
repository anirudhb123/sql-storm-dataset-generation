WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_suppkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty * ps.ps_supplycost AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
)
SELECT 
    r.r_name,
    ns.n_name AS supplier_nation,
    SUM(COALESCE(ps.total_supply_cost, 0)) AS total_cost,
    AVG(cs.total_spent) AS average_customer_spent,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    row_number() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(COALESCE(ps.total_supply_cost, 0)) DESC) AS region_rank
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN PartSupplier ps ON ps.p_partkey IN (
    SELECT p_partkey 
    FROM part 
    WHERE p_size BETWEEN 10 AND 20
)
LEFT JOIN CustomerSummary cs ON cs.order_count > 5
WHERE ns.n_nationkey IN (
    SELECT DISTINCT s_nationkey
    FROM SupplierHierarchy
    WHERE level <= 2
)
GROUP BY r.r_regionkey, ns.n_name
HAVING SUM(COALESCE(ps.total_supply_cost, 0)) > 10000
ORDER BY region_rank, total_cost DESC;
