WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer AS c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer AS c
    JOIN CustomerHierarchy AS ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
), 

OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders AS o
    JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
), 

SupplierDetails AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS parts_supplied,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier AS s
    LEFT JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)

SELECT 
    r.r_name, 
    n.n_name, 
    SUM(COALESCE(os.total_revenue, 0)) AS total_order_revenue,
    AVG(sd.avg_supply_cost) AS average_supplier_cost,
    COUNT(DISTINCT ch.c_custkey) AS distinct_customers,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region AS r
JOIN nation AS n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerHierarchy AS ch ON n.n_nationkey = ch.c_nationkey
LEFT JOIN OrderSummary AS os ON ch.c_custkey = os.o_orderkey
LEFT JOIN SupplierDetails AS sd ON sd.parts_supplied > 0
LEFT JOIN partsupp AS ps ON sd.s_suppkey = ps.ps_suppkey
LEFT JOIN part AS p ON ps.ps_partkey = p.p_partkey
WHERE r.r_name IS NOT NULL 
  AND n.n_name IS NOT NULL 
  AND p.p_retailprice < 200
GROUP BY r.r_name, n.n_name
ORDER BY total_order_revenue DESC, average_supplier_cost ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
