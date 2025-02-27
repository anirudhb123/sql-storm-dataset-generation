WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
AggregatedOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost, COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_size, p.p_retailprice,
           COALESCE(MAX(l.l_quantity), 0) AS max_order_quantity,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_size, p.p_retailprice
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
FinalResults AS (
    SELECT pd.p_partkey, pd.p_name, pd.p_brand, pd.p_size, pd.p_retailprice,
           ps.avg_supply_cost, ps.unique_suppliers, 
           COALESCE(ao.total_spent, 0) AS customer_spending,
           COALESCE(sh.level, 0) AS supplier_level,
           rs.rank AS supplier_rank
    FROM PartDetails pd
    LEFT JOIN PartSupplierStats ps ON pd.p_partkey = ps.ps_partkey
    LEFT JOIN AggregatedOrders ao ON ao.c_custkey = (SELECT MAX(c.c_custkey) FROM customer c)
    LEFT JOIN SupplierHierarchy sh ON 1 = 1
    LEFT JOIN RankedSuppliers rs ON rs.s_suppkey = (SELECT MAX(s.s_suppkey) FROM supplier s)
)
SELECT *
FROM FinalResults
WHERE unique_suppliers > 5 
AND (customer_spending > 0 OR supplier_level > 1)
ORDER BY p_retailprice DESC, total_revenue DESC;
