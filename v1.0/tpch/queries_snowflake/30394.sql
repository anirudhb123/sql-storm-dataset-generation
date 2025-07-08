
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, NULL AS parent_key
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
    WHERE s.s_suppkey <> sh.parent_key
),
FrequentCustomers AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
PartPricing AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost, MAX(p.p_retailprice) AS max_retail_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    n.n_name,
    r.r_name,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END) AS total_returned,
    COUNT(DISTINCT f.c_custkey) AS frequent_customers,
    COALESCE(p.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(p.max_retail_price, 0) AS max_retail_price,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN lineitem li ON li.l_suppkey = s.s_suppkey
LEFT JOIN FrequentCustomers f ON f.c_custkey = li.l_orderkey
LEFT JOIN PartPricing p ON p.p_partkey = li.l_partkey
LEFT JOIN SupplierHierarchy sh ON sh.parent_key = s.s_suppkey
WHERE n.n_comment IS NOT NULL
GROUP BY n.n_name, r.r_name, p.avg_supply_cost, p.max_retail_price, sh.s_suppkey
HAVING SUM(li.l_quantity) > 100
ORDER BY total_returned DESC, frequent_customers DESC;
