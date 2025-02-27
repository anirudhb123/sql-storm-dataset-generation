WITH RecursiveCTE AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
),
AggregatedOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    GROUP BY o.o_custkey
    HAVING SUM(o.o_totalprice) > 1000.00
),
LineItemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierPerformance AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CombinedData AS (
    SELECT r.r_regionkey, r.r_name, r.r_comment, COALESCE(sp.total_supply_cost, 0) AS total_supplier_cost, 
           COALESCE(ao.total_spent, 0) AS total_customer_spent, 
           COALESCE(ld.total_line_item_value, 0) AS total_line_item_value
    FROM region r
    LEFT JOIN SupplierPerformance sp ON r.r_regionkey = sp.s_suppkey % 5
    LEFT JOIN AggregatedOrders ao ON sp.s_suppkey = ao.o_custkey
    LEFT JOIN LineItemDetails ld ON ld.l_orderkey = ao.o_custkey
)
SELECT DISTINCT c.c_custkey, c.c_name, cd.total_customer_spent, 
                ROW_NUMBER() OVER(PARTITION BY cd.r_name ORDER BY cd.total_customer_spent DESC) AS rank_within_region
FROM customer c
JOIN CombinedData cd ON cd.total_customer_spent > c.c_acctbal
WHERE c.c_name ILIKE '%A%' AND cd.total_line_item_value BETWEEN 500 AND 5000
ORDER BY rank_within_region, cd.total_customer_spent DESC
OFFSET (SELECT COUNT(*) FROM customer) * 0.1
LIMIT 10;


