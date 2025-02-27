WITH RecursivePart AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           p.p_container, 
           CASE 
               WHEN p.p_size IS NULL THEN 'Unknown Size' 
               ELSE CAST(p.p_size AS VARCHAR)
           END AS size_description 
    FROM part p
    WHERE p.p_retailprice > 100 AND p.p_container NOT LIKE '%box%'
    UNION ALL
    SELECT p.p_partkey, 
           p.p_name || ' - ' || rp.size_description, 
           p.p_retailprice, 
           p.p_container, 
           rp.size_description 
    FROM part p
    INNER JOIN RecursivePart rp ON p.p_partkey = rp.p_partkey
    WHERE p.p_retailprice / NULLIF(rp.p_retailprice, 0) < 2
),
SupplierWithDiscount AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * (1 - CASE WHEN l.l_discount IS NULL THEN 0 ELSE l.l_discount END)) AS effective_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) > 10 OR SUM(l.l_quantity) > 1000
),
CustomerOrderInfo AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
),
SupplierCustomerRanking AS (
    SELECT s.s_suppkey,
           s.s_name,
           ci.c_custkey,
           ci.c_name,
           RANK() OVER (PARTITION BY s.s_suppkey ORDER BY ci.total_spent DESC) AS rank,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ci.total_orders DESC) AS order_rank
    FROM SupplierWithDiscount s
    JOIN CustomerOrderInfo ci ON s.s_suppkey = ci.c_custkey
    WHERE s.effective_cost < (SELECT AVG(effective_cost) FROM SupplierWithDiscount)
)
SELECT r.r_name, 
       sp.p_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       MAX(sp.size_description) AS largest_size_description,
       CASE 
           WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Volume' 
           ELSE 'Low Volume' 
       END AS order_volume_status
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part sp ON ps.ps_partkey = sp.p_partkey
JOIN lineitem l ON l.l_partkey = sp.p_partkey
JOIN orders o ON o.o_orderkey = l.l_orderkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name, sp.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 OR SUM(l.l_extendedprice) IS NULL
ORDER BY total_sales DESC, MAX(sp.size_description) ASC;
