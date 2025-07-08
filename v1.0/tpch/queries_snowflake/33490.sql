WITH RECURSIVE RegionCTE AS (
    SELECT r_regionkey, r_name, r_comment
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment
    FROM region r
    JOIN RegionCTE rc ON r.r_regionkey = rc.r_regionkey + 1
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, 
           COALESCE(SUM(ps.ps_availqty), 0) AS total_available, 
           AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.total_available, s.avg_acctbal,
           ROW_NUMBER() OVER (ORDER BY s.total_available DESC) AS rank
    FROM SupplierStats s
),
CustomerOrderAnalysis AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredCustomers AS (
    SELECT * 
    FROM CustomerOrderAnalysis
    WHERE order_count > 5 AND total_spent > 1000
)
SELECT r.r_name AS region, 
       p.p_name AS part_name, 
       s.s_name AS supplier_name,
       c.c_name AS customer_name,
       CASE 
           WHEN l.l_discount > 0.1 THEN 'Discounted' 
           ELSE 'Regular Price' 
       END AS price_category,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN FilteredCustomers c ON o.o_custkey = c.c_custkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE o.o_orderstatus = 'O'
  AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY r.r_name, p.p_name, s.s_name, c.c_name, l.l_discount
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY total_revenue DESC
LIMIT 10;