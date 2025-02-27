WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 0 AS depth
    FROM part
    WHERE p_size IS NOT NULL
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice, ph.depth + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey + 1
    WHERE ph.depth < 5
),
AggregatedPrices AS (
    SELECT ps_partkey, SUM(ps_supplycost) AS total_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
),
CustomerPurchases AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acct_bal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
SupplyQuality AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.s_suppkey) AS unique_suppliers,
           AVG(l.l_discount) AS avg_discount
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey
),
FinalReport AS (
    SELECT ph.p_name, ph.p_retailprice, ap.total_supply_cost,
           cp.order_count, cp.total_spent,
           ns.supplier_count, ns.avg_acct_bal,
           sq.unique_suppliers, sq.avg_discount
    FROM PartHierarchy ph
    INNER JOIN AggregatedPrices ap ON ph.p_partkey = ap.ps_partkey
    LEFT JOIN CustomerPurchases cp ON cp.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY RANDOM() LIMIT 1) 
    LEFT JOIN NationStats ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n ORDER BY RANDOM() LIMIT 1)
    LEFT JOIN SupplyQuality sq ON sq.p_partkey = ph.p_partkey
)
SELECT * 
FROM FinalReport
WHERE (total_spent IS NULL OR total_spent > 1000) 
AND (avg_discount BETWEEN 0.1 AND 0.5 OR avg_discount IS NULL)
ORDER BY p_name ASC, total_supply_cost DESC
LIMIT 50 OFFSET (SELECT FLOOR(RANDOM() * COUNT(*)) FROM FinalReport);
