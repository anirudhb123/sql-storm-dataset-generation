WITH SuppliersWithHighBalance AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_container, 
           COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice, p.p_container
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
),
QualifiedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, 
           COALESCE(l.net_revenue, 0) AS net_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN LineItemAnalysis l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
),
FinalStats AS (
    SELECT p.p_name, pd.s_name, SUM(lo.net_revenue) AS total_revenue,
           AVG(COALESCE(pd.supplier_count, 0)) AS avg_supplier_count
    FROM PartDetails pd
    JOIN SuppliersWithHighBalance swhb ON pd.supplier_count > 0
    LEFT JOIN lineitem l ON pd.p_partkey = l.l_partkey
    LEFT JOIN QualifiedOrders lo ON l.l_orderkey = lo.o_orderkey
    GROUP BY p.p_name, swhb.s_name
)
SELECT r.r_name, COUNT(DISTINCT f.p_name) AS distinct_parts,
       SUM(f.total_revenue) AS total_revenue,
       MAX(f.avg_supplier_count) AS max_avg_suppliers
FROM FinalStats f
JOIN nation n ON f.s_name = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY total_revenue DESC;
