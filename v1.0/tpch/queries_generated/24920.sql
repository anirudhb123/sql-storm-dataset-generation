WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderCounts AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    GROUP BY o.o_custkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           CASE 
               WHEN o.o_totalprice > (SELECT AVG(o_totprice) FROM orders) THEN 'High Value'
               ELSE 'Standard Value'
           END AS order_value_category
    FROM orders o
)
SELECT 
    c.c_name AS customer_name,
    c.c_address,
    COALESCE(MAX(CASE WHEN ps.ps_availqty IS NULL THEN NULL ELSE ps.ps_availqty END), 0) AS max_avail_qty,
    COUNT(DISTINCT lo.l_orderkey) AS total_orders,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS net_revenue,
    (SELECT COUNT(*) FROM HighValueOrders hvo WHERE hvo.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = rs.s_suppkey)) AS high_value_order_count
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem lo ON o.o_orderkey = lo.l_orderkey
LEFT JOIN partsupp ps ON lo.l_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rnk = 1
LEFT JOIN CustomerOrderCounts coc ON c.c_custkey = coc.o_custkey
WHERE o.o_orderstatus = 'O' 
AND (c.c_acctbal IS NULL OR c.c_acctbal > 1000)
GROUP BY c.c_name, c.c_address
ORDER BY net_revenue DESC, max_avail_qty ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
