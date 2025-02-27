WITH SupplierAggregate AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
),
CustomerNation AS (
    SELECT c.c_custkey, c.c_name, n.n_name, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    cn.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.net_revenue) AS average_order_revenue,
    SUM(s.total_supplycost) AS total_supplier_costs
FROM CustomerNation cn
LEFT JOIN OrderSummary o ON cn.c_custkey IN (
    SELECT o.o_custkey 
    FROM orders o 
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate > '2023-01-01'
)
LEFT JOIN SupplierAggregate s ON s.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
GROUP BY cn.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_orders DESC, average_order_revenue DESC;
