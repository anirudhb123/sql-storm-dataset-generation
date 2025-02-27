WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size > 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT 
    r.n_nationkey,
    r.n_name,
    COALESCE(SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END), 0) AS total_supply,
    COUNT(DISTINCT CASE WHEN rp.rank = 1 THEN rp.p_partkey END) AS top_parts,
    AVG(hvo.o_totalprice) AS avg_high_value_order,
    COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count
FROM nation r
LEFT JOIN supplier s ON r.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = (SELECT MIN(h.o_orderkey) FROM HighValueOrders h WHERE h.o_totalprice = hvo.o_totalprice)
WHERE r.n_comment IS NOT NULL
GROUP BY r.n_nationkey, r.n_name
HAVING COUNT(DISTINCT rp.p_partkey) > 0 OR AVG(hvo.o_totalprice) IS NOT NULL
ORDER BY total_supply DESC, high_value_order_count DESC;
