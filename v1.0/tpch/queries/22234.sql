WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(CASE 
        WHEN ps.ps_availqty IS NULL THEN 0 
        ELSE ps.ps_availqty 
        END) AS total_available_quantity,
    AVG(o_totalprice) FILTER (WHERE o_orderstatus = 'O') AS average_open_order_price,
    STRING_AGG(DISTINCT s.s_name || ' (' || COALESCE(s.s_comment, 'No comment') || ')', ', ') AS suppliers_info,
    (SELECT COUNT(*) FROM CustomerOrderCount c)
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN RankedOrders ro ON ro.o_orderkey = (
        SELECT l.l_orderkey 
        FROM lineitem l
        WHERE l.l_partkey = p.p_partkey 
        ORDER BY l.l_shipdate DESC 
        LIMIT 1) 
GROUP BY r.r_name, n.n_name
HAVING SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp) AND 
       COUNT(DISTINCT n.n_nationkey) > 1 
ORDER BY total_available_quantity DESC 
LIMIT 10;
