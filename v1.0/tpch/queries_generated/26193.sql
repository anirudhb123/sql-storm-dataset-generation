WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        c.c_name,
        c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name, c.c_mktsegment
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    np.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(order_value) AS average_order_value,
    SUM(CASE WHEN rp.price_rank <= 3 THEN 1 ELSE 0 END) AS top_part_count,
    COUNT(DISTINCT ss.s_suppkey) AS unique_suppliers
FROM region r
JOIN nation np ON np.n_regionkey = r.r_regionkey
JOIN customer c ON c.c_nationkey = np.n_nationkey
JOIN orders o ON o.o_custkey = c.c_custkey
JOIN HighValueOrders hvo ON o.o_orderkey = hvo.o_orderkey
LEFT JOIN RankedParts rp ON rp.p_brand = 'Brand#1'  -- Arbitrary brand for filtering
LEFT JOIN SupplierSummary ss ON ss.part_count > 5
GROUP BY r.r_name, np.n_name
ORDER BY total_orders DESC, average_order_value DESC;
