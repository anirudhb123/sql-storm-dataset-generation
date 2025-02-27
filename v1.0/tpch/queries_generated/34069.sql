WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
CustomerTotal AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
LineItemSummary AS (
    SELECT l.l_partkey, COUNT(*) AS total_lines, AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    GROUP BY l.l_partkey
),
CombinedStats AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COALESCE(l.total_lines, 0) AS total_lines,
           COALESCE(l.avg_price, 0) AS avg_price,
           COALESCE(sc.total_cost, 0) AS total_cost,
           COALESCE(ct.total_spent, 0) AS total_spent,
           nh.level AS nation_level
    FROM part p
    LEFT JOIN LineItemSummary l ON p.p_partkey = l.l_partkey
    LEFT JOIN SupplierCost sc ON p.p_partkey = sc.ps_partkey
    LEFT JOIN CustomerTotal ct ON ct.total_spent > 50000
    LEFT JOIN NationHierarchy nh ON p.p_partkey % 10 = nh.n_nationkey
)
SELECT c.p_partkey, c.p_name, c.p_retailprice,
       c.total_lines, c.avg_price, c.total_cost, 
       RANK() OVER (ORDER BY c.total_spent DESC, c.p_retailprice ASC) AS sales_rank
FROM CombinedStats c
WHERE c.nation_level > 0
ORDER BY sales_rank, c.p_name;
