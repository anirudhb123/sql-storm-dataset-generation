WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    ps.total_cost,
    os.total_sales,
    sh.level AS supplier_level,
    CASE WHEN os.sales_rank = 1 THEN 'Top Order' ELSE 'Regular Order' END AS order_category
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
JOIN OrderSummary os ON os.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey ORDER BY o.o_totalprice DESC LIMIT 1)
JOIN PartSupplier ps ON ps.p_partkey = (SELECT li.l_partkey 
                                           FROM lineitem li 
                                           WHERE li.l_orderkey = os.o_orderkey 
                                           ORDER BY li.l_extendedprice DESC LIMIT 1)
WHERE c.c_acctbal IS NOT NULL 
      AND sh.s_acctbal BETWEEN 100000.00 AND 500000.00
ORDER BY r.r_name, n.n_name, ps.total_cost DESC;
