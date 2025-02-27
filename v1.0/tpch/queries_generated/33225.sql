WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate > '2023-01-01'
),
LineItemDetails AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM lineitem li
    WHERE li.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY li.l_orderkey
),
SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.total_revenue) AS total_supplier_revenue
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    INNER JOIN CustomerOrders co ON l.l_orderkey = co.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT sr.*, RANK() OVER (ORDER BY sr.total_supplier_revenue DESC) AS revenue_rank
    FROM SupplierRevenue sr
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(sh.s_suppkey) AS supplier_count,
    AVG(sh.s_acctbal) AS average_balance,
    COALESCE(rs.total_supplier_revenue, 0) AS total_revenue,
    COALESCE(rs.revenue_rank, 0) AS rank
FROM nation ns
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
WHERE ns.n_name IS NOT NULL
GROUP BY ns.n_name
ORDER BY supplier_count DESC, average_balance DESC;
