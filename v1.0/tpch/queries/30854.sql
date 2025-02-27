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
SalesSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS item_count,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
RankedSales AS (
    SELECT 
        ss.o_orderkey,
        ss.total_sales,
        ss.item_count,
        ss.o_orderdate,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM ss.o_orderdate) ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SalesSummary ss
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(COALESCE(ps.ps_availqty, 0) * p.p_retailprice) AS total_inventory_value,
    COUNT(DISTINCT l.l_orderkey) AS orders_count,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS returns_count,
    MAX(CASE WHEN c.c_mktsegment = 'BUILDING' THEN c.c_acctbal ELSE NULL END) AS max_building_cust_acctbal,
    sh.s_name AS supplier_name,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS part_sales_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN customer c ON l.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey LIMIT 1)
WHERE p.p_retailprice > 20 
AND sh.s_acctbal IS NOT NULL
GROUP BY p.p_partkey, p.p_name, sh.s_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY total_inventory_value DESC, part_sales_rank ASC;
