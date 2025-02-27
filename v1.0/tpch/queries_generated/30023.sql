WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) as supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
HighValueCustomers AS (
    SELECT * FROM CustomerOrders
    WHERE total_spent > (
        SELECT AVG(total_spent) FROM CustomerOrders
    )
)
SELECT r.r_name AS region_name, n.n_name AS nation_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
       AVG(s.s_acctbal) AS avg_supplier_balance
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplyChain sc ON c.c_custkey IN (
    SELECT s.s_suppkey FROM SupplierChain WHERE supplier_rank <= 5
)
WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY r.r_name, n.n_name
HAVING total_sales > (
    SELECT AVG(total_sales) 
    FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_sales
        FROM lineitem 
        JOIN orders ON lineitem.l_orderkey = orders.o_orderkey
        GROUP BY lineitem.l_orderkey
    ) AS subquery
)
ORDER BY total_sales DESC;
