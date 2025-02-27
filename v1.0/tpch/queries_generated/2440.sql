WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
), RecentOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
), LineItemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(*) AS line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
), PartsPerSupplier AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_availqty) AS total_qty
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
), CombinedData AS (
    SELECT r.r_name, COALESCE(l.total_price, 0) AS recent_total_price, 
           COALESCE(p.total_qty, 0) AS supplier_total_qty, 
           COALESCE(rs.s_name, 'No supplier') AS supplier_name,
           rs.s_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rnk = 1
    LEFT JOIN RecentOrders o ON n.n_nationkey = o.c_nationkey
    LEFT JOIN LineItemDetails l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN PartsPerSupplier p ON rs.s_suppkey = p.ps_suppkey
)
SELECT cd.r_name, SUM(cd.recent_total_price) AS total_recent_sales, 
       AVG(cd.supplier_total_qty) AS avg_supply_qty, 
       COUNT(DISTINCT cd.supplier_name) AS distinct_suppliers
FROM CombinedData cd
WHERE cd.recent_total_price > 100000
GROUP BY cd.r_name
ORDER BY total_recent_sales DESC
LIMIT 10;
