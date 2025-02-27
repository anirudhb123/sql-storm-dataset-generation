WITH RECURSIVE DateRange AS (
    SELECT MIN(o_orderdate) AS order_date
    FROM orders
    UNION ALL
    SELECT DATE_ADD(order_date, INTERVAL 1 DAY)
    FROM DateRange
    WHERE order_date < (SELECT MAX(o_orderdate) FROM orders)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
),
PartSuppAnalysis AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemSummary AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE_SUB(CURDATE(), INTERVAL 60 DAY) AND CURDATE()
    GROUP BY l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(pl.total_available, 0) AS total_available,
    COALESCE(ls.net_revenue, 0) AS net_revenue,
    COALESCE(co.total_spent, 0) AS total_spent_by_customers,
    DATEDIFF(CURDATE(), MIN(o.o_orderdate)) AS days_since_first_order
FROM 
    part p
LEFT JOIN PartSuppAnalysis pl ON p.p_partkey = pl.ps_partkey
LEFT JOIN LineItemSummary ls ON p.p_partkey = ls.l_partkey
LEFT JOIN CustomerOrders co ON co.order_count > 10
LEFT JOIN orders o ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
GROUP BY 
    p.p_partkey,
    p.p_name,
    p.p_retailprice
HAVING 
    total_available > 100 OR net_revenue > 1000
ORDER BY 
    total_available DESC, net_revenue DESC;
