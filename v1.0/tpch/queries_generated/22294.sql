WITH RECURSIVE part_supplier_stats AS (
    SELECT 
        ps.suppkey,
        ps.partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        CAST(NULLIF(SUBSTRING_INDEX(SUM(ps.ps_comment), ' ', -1), '') AS CHAR(10)) AS last_word_comment
    FROM partsupp ps
    GROUP BY ps.suppkey, ps.partkey
),
ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn,
        COUNT(p.p_partkey) OVER (PARTITION BY p.p_brand) AS brand_count
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    ns.n_name AS supplier_nation,
    SUM(p.total_avail_qty * COALESCE(ol.l_discount, 0)) AS discounted_total_avail,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(datetime('now') - datetime(c.last_order_date)) AS days_since_last_order,
    p.p_name,
    CASE
        WHEN p.brand_count > 3 THEN 'Popular'
        ELSE 'Niche'
    END AS supplier_niche
FROM part_supplier_stats p
INNER JOIN supplier s ON s.s_suppkey = p.suppkey 
LEFT JOIN nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN customer_orders c ON c.order_count > 0
LEFT JOIN ranked_parts rp ON p.partkey = rp.p_partkey AND rp.rn = 1
LEFT JOIN (
    SELECT l.*
    FROM lineitem l
    WHERE l.l_shipdate > DATE('2022-01-01')
      AND l.l_returnflag = 'Y'
) ol ON ol.l_orderkey = c.o_orderkey
GROUP BY ns.n_name, p.p_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY discounted_total_avail DESC, supplier_nation DESC
LIMIT 50;
