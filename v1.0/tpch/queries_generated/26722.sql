WITH StringJoin AS (
    SELECT CONCAT(s.s_name, ' from ', p.p_name, ' is available at a price of $', FORMAT(ps.ps_supplycost, 2)) AS ProductInfo
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
FilteredInfo AS (
    SELECT SUBSTRING(ProductInfo, 1, 50) AS ShortInfo
    FROM StringJoin
    WHERE LENGTH(ProductInfo) > 50
),
RegionSummary AS (
    SELECT CONCAT(r.r_name, ': ', COUNT(DISTINCT n.n_nationkey), ' nations served') AS RegionInfo
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    ShortInfo,
    (SELECT STRING_AGG(RegionInfo, '; ') FROM RegionSummary) AS Regions
FROM FilteredInfo
ORDER BY ShortInfo;
