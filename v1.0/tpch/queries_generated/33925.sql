WITH RECURSIVE price_hike AS (
    SELECT 
        p_partkey,
        p_name,
        p_retailprice,
        0 AS hike_level
    FROM part
    WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part)
    
    UNION ALL
    
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice * 1.1,
        ph.hike_level + 1
    FROM price_hike ph
    JOIN part p ON p.p_partkey = ph.p_partkey
    WHERE ph.hike_level < 5
),
nation_suppliers AS (
    SELECT 
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.p_retailprice,
    ns.n_name,
    ns.supplier_count,
    ro.o_orderkey,
    ro.o_totalprice,
    ro.total_price_rank
FROM price_hike ph
LEFT JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
LEFT JOIN nation_suppliers ns ON ns.supplier_count > 0
LEFT JOIN ranked_orders ro ON ro.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
WHERE ph.p_retailprice IS NOT NULL
AND ns.n_name IS NOT NULL
ORDER BY ph.p_partkey, ro.total_price_rank ASC;
