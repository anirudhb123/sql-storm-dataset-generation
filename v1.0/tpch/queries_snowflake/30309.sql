
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, CAST(NULL AS integer) AS parent_suppkey, s.s_acctbal, s.s_comment
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.s_suppkey, s.s_acctbal, s.s_comment
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerAvgBalance AS (
    SELECT c.c_nationkey, AVG(c.c_acctbal) AS avg_balance
    FROM customer c
    GROUP BY c.c_nationkey
),
RegionData AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nations_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN partsupp ps ON n.n_nationkey = ps.ps_suppkey
    GROUP BY r.r_regionkey
)
SELECT 
    rh.s_name AS supplier_name,
    od.o_orderkey,
    od.total_revenue,
    ca.avg_balance,
    rd.total_supplier_cost,
    rd.nations_count,
    CASE 
        WHEN od.total_revenue > ca.avg_balance THEN 'Above Average'
        ELSE 'Below Average'
    END AS revenue_status
FROM SupplierHierarchy rh
JOIN OrderDetails od ON od.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_nationkey = rh.s_suppkey
)
JOIN CustomerAvgBalance ca ON ca.c_nationkey = rh.s_suppkey
JOIN RegionData rd ON rd.r_regionkey = ANY (
    SELECT r.r_regionkey
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    WHERE n.n_nationkey = rh.s_suppkey
)
GROUP BY 
    rh.s_name, 
    od.o_orderkey, 
    od.total_revenue, 
    ca.avg_balance, 
    rd.total_supplier_cost, 
    rd.nations_count
ORDER BY rd.total_supplier_cost DESC, od.total_revenue DESC
LIMIT 50;
