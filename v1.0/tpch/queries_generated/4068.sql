WITH SupplierCosts AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.s_suppkey
),
CustomerOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY o.o_custkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    PARTS.p_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(c.total_spent) AS avg_customer_spent,
    s.total_cost AS supplier_cost,
    CASE 
        WHEN COUNT(DISTINCT li.l_orderkey) > 5 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS order_volume,
    RANK() OVER (ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
FROM lineitem li
JOIN RankedOrders ro ON li.l_orderkey = ro.o_orderkey
JOIN CustomerOrders c ON ro.o_custkey = c.o_custkey
JOIN PartDetails PARTS ON li.l_partkey = PARTS.p_partkey
LEFT JOIN SupplierCosts s ON li.l_suppkey = s.s_suppkey
GROUP BY c.c_name, PARTS.p_name, s.total_cost
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY revenue_rank;
