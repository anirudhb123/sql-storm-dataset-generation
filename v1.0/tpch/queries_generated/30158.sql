WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_suppkey = sh.s_suppkey
    WHERE sp.s_acctbal < sh.s_acctbal
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, cos.total_spent,
           RANK() OVER (ORDER BY cos.total_spent DESC) AS spend_rank
    FROM CustomerOrderStats cos
    JOIN customer c ON cos.c_custkey = c.c_custkey
),
TotalRevenuePerNation AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT
    r.r_name,
    SUM(tr.total_revenue) AS regional_revenue,
    COUNT(DISTINCT r.n_nationkey) AS nation_count,
    COUNT(DISTINCT sh.s_suppkey) AS high_account_suppliers,
    AVG(ps.avg_supply_cost) AS avg_supply_cost,
    MAX(rc.total_spent) AS max_customer_spending
FROM region r
LEFT JOIN TotalRevenuePerNation tr ON r.r_regionkey = tr.n_nationkey
LEFT JOIN SupplierHierarchy sh ON r.r_regionkey = sh.s_suppkey
LEFT JOIN PartSupplierStats ps ON ps.supplier_count > 10
LEFT JOIN RankedCustomers rc ON rc.spend_rank <= 10
GROUP BY r.r_name
HAVING regional_revenue > (
    SELECT AVG(total_revenue)
    FROM TotalRevenuePerNation
)
ORDER BY regional_revenue DESC;
