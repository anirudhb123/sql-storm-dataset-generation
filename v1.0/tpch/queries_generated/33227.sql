WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = (SELECT MIN(n_nationkey) FROM nation)
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    nh.n_name AS nation_name,
    ps.total_parts,
    ps.total_supply_cost,
    os.total_revenue,
    rp.p_name AS top_product,
    rp.p_retailprice,
    CASE 
        WHEN ps.total_supply_cost IS NULL THEN 'No supply data'
        ELSE CONCAT('Cost: ', CAST(ps.total_supply_cost AS VARCHAR))
    END AS supply_cost_info
FROM SupplierStats ps
LEFT JOIN OrderSummary os ON os.line_item_count > 100
JOIN RankedProducts rp ON ps.total_parts > 5 AND rp.price_rank = 1
JOIN NationHierarchy nh ON ps.total_parts IS NOT NULL
WHERE nh.level < 2 OR os.total_revenue > 10000
ORDER BY nh.n_name, ps.total_supply_cost DESC;
