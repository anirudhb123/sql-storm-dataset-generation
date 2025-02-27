WITH RECURSIVE PriceHierarchy AS (
    SELECT p_partkey, p_retailprice, p_name, CAST(p_name AS VARCHAR(100)) AS hierarchy
    FROM part
    WHERE p_retailprice > 0
    UNION ALL
    SELECT ph.p_partkey, p.p_retailprice, p.p_name, CONCAT(ph.hierarchy, ' -> ', p.p_name)
    FROM PriceHierarchy ph
    JOIN part p ON p.p_partkey = ph.p_partkey + 1
),
TotalSales AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT
        ts.o_orderkey,
        ts.total_sales,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM TotalSales ts
    WHERE ts.total_sales IS NOT NULL
),
NationSupplier AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    nh.n_name,
    COUNT(DISTINCT ps.p_partkey) AS parts_available,
    AVG(RANKED.total_sales) AS avg_order_sales,
    MAX(pi.hierarchy) AS product_hierarchy
FROM NationSupplier nh
LEFT JOIN SupplierInfo si ON si.total_supply_cost > 0
LEFT JOIN PriceHierarchy pi ON pi.p_partkey = si.s_suppkey
JOIN RankedSales RANKED ON RANKED.sales_rank < 10
WHERE nh.supplier_count IS NULL OR nh.n_name IS NOT NULL
GROUP BY nh.n_name
HAVING SUM(COALESCE(si.total_supply_cost, 0)) > 10000
ORDER BY parts_available DESC, avg_order_sales ASC;
