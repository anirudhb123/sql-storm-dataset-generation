WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE LENGTH(p.p_name) > 10 AND p.p_retailprice > (
        SELECT AVG(p_sub.p_retailprice) FROM part p_sub WHERE p_sub.p_type LIKE '%metal%'
    )
),
AggregatedData AS (
    SELECT 
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS available_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_name, n.n_name
),
FinalResults AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ad.available_parts) AS total_available_parts,
        SUM(ad.total_supply_cost) AS total_cost,
        STRING_AGG(DISTINCT rp.p_name, ', ') AS top_products
    FROM region r
    JOIN nation n ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN RankedProducts rp ON rp.p_partkey = ps.ps_partkey
    JOIN AggregatedData ad ON s.s_name = ad.supplier_name
    GROUP BY r.r_name
)
SELECT 
    *,
    CONCAT('Region: ', region_name, ' | Total Available Parts: ', total_available_parts, 
           ' | Total Cost: $', total_cost, ' | Top Products: ', top_products) AS benchmark_info
FROM FinalResults
ORDER BY total_available_parts DESC, total_cost DESC;
