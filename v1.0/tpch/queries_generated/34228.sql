WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate AND oh.level < 5
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM lineitem l
    WHERE l.l_discount > 0 AND l.l_discount < 0.1
)
SELECT 
    r.r_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    MAX(o.o_orderdate) AS last_order_date,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts_supplied,
    COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN RankedLineItems l ON p.p_partkey = l.l_partkey
JOIN OrderHierarchy o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
GROUP BY r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_revenue)
                                                      FROM (
                                                          SELECT SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS total_revenue
                                                          FROM RankedLineItems l2
                                                          GROUP BY l2.l_orderkey
                                                      ) revenue_avg)
ORDER BY total_revenue DESC
LIMIT 10;
