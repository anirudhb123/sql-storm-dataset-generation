WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.depth < 3
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(cod.total_revenue) AS total_revenue,
           RANK() OVER (ORDER BY SUM(cod.total_revenue) DESC) AS revenue_rank
    FROM customer c
    JOIN CustomerOrderDetails cod ON c.c_custkey = cod.c_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRevenue AS (
    SELECT n.n_name, SUM(r.total_revenue) AS total_revenue
    FROM nation n
    LEFT JOIN RankedCustomers rc ON n.n_nationkey = rc.c_custkey
    GROUP BY n.n_name
)
SELECT nh.n_name,
       COALESCE(sp.total_supplycost, 0) AS supply_cost,
       COALESCE(nr.total_revenue, 0) AS nation_revenue
FROM (SELECT n_name, ROW_NUMBER() OVER (ORDER BY n_name) AS n_row
      FROM nation) AS nh
LEFT JOIN PartSummary sp ON nh.n_row % 5 = 0
LEFT JOIN NationRevenue nr ON nh.n_name = nr.n_name
ORDER BY nh.n_name;
