WITH RankedSales AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rank
    FROM lineitem
    GROUP BY l_orderkey
),
SupplierStats AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerSales AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT n.n_name, 
       COALESCE(SUM(CASE WHEN cs.total_spent IS NOT NULL THEN cs.total_spent ELSE 0 END), 0) AS total_cust_spent,
       COALESCE(SUM(rs.total_sales), 0) AS total_order_sales,
       COUNT(DISTINCT ss.s_suppkey) AS total_suppliers,
       STRING_AGG(DISTINCT p.p_name, '; ') FILTER (WHERE p.p_size < 30) AS small_parts
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerSales cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN RankedSales rs ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey)
LEFT JOIN partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 50)
LEFT JOIN supplier ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE r.r_name IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT ss.s_suppkey) > 2 OR COUNT(DISTINCT p.p_partkey) > 5
ORDER BY total_order_sales DESC NULLS LAST;
