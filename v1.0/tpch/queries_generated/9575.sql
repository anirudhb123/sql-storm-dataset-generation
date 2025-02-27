WITH FrequentSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS supplier_part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(ps.ps_partkey) > 10
),
RegionalOrders AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, COUNT(o.o_orderkey) AS total_orders
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
),
ProductDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    HAVING SUM(l.l_quantity) > 100
)
SELECT 
    r.region_name,
    r.nation_name,
    fs.s_name AS supplier_name,
    pd.p_name AS product_name,
    pd.total_quantity_sold,
    r.total_orders
FROM RegionalOrders r
JOIN FrequentSuppliers fs ON fs.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN ProductDetails pd ON ps.ps_partkey = pd.p_partkey
    GROUP BY ps.ps_suppkey
)
JOIN ProductDetails pd ON pd.total_quantity_sold > 0
ORDER BY r.region_name, r.nation_name, fs.s_name, pd.total_quantity_sold DESC;
