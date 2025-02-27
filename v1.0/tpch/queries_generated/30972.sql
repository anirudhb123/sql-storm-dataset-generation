WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey)
    WHERE o.o_orderdate >= '2023-01-01'
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        s.s_nationkey, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_nationkey
),
RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice * (1 - l.l_discount) AS net_price,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_shipdate <= '2023-12-31'
)
SELECT 
    r.r_name AS supplier_region,
    p.p_name AS part_name,
    COUNT(DISTINCT ol.o_orderkey) AS order_count,
    SUM(rli.net_price) AS total_revenue,
    COALESCE(SUM(ps.total_avail_qty), 0) AS total_available
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN PartSuppliers ps ON s.s_suppkey = ps.s_nationkey
JOIN RankedLineItems rli ON ps.ps_partkey = rli.l_partkey
JOIN OrderHierarchy ol ON rli.l_orderkey = ol.o_orderkey
JOIN part p ON rli.l_partkey = p.p_partkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name, p.p_name
HAVING COUNT(DISTINCT ol.o_orderkey) > 0
ORDER BY total_revenue DESC;
