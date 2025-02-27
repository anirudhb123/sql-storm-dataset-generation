WITH RECURSIVE RankedOrders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_orderstatus,
           RANK() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    WHERE o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
),
FrequentSuppliers AS (
    SELECT ps.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS supplier_part_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.s_suppkey
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
HighValueCustomers AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 10000
    ORDER BY total_spent DESC
),
RelevantPartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(o.o_totalprice) AS total_orders_value,
    AVG(p.p_retailprice) AS average_part_price,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY total_orders_value DESC) AS order_ranking
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN RelevantPartInfo p ON p.p_partkey = ps.ps_partkey
JOIN FrequentSuppliers fs ON s.s_suppkey = fs.s_suppkey
JOIN HighValueCustomers c ON c.c_custkey = o.o_custkey
JOIN orders o ON o.o_custkey = c.c_custkey
GROUP BY r.r_name, n.n_name, s.s_name, c.c_name
HAVING SUM(o.o_totalprice) > 5000
ORDER BY total_orders_value DESC;
