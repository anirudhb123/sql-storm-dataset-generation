WITH ParsedNames AS (
    SELECT 
        p_partkey,
        TRIM(SUBSTRING_INDEX(p_name, ' ', 1)) AS FirstWord,
        TRIM(SUBSTRING_INDEX(p_name, ' ', -1)) AS LastWord,
        LENGTH(p_name) AS NameLength
    FROM part
),
SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(s_suppkey) AS SupplierCount,
        AVG(s_acctbal) AS AvgAccountBalance
    FROM supplier
    GROUP BY s_nationkey
),
CombinedResults AS (
    SELECT 
        r.r_name AS RegionName,
        n.n_name AS NationName,
        COUNT(DISTINCT p.p_partkey) AS TotalParts,
        COUNT(DISTINCT s.s_suppkey) AS TotalSuppliers,
        SUM(ps.ps_supplycost) AS TotalSupplyCost,
        AVG(pn.NameLength) AS AvgPartNameLength,
        AVG(ss.AvgAccountBalance) AS AvgSupplierAccountBalance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN ParsedNames pn ON p.p_partkey = pn.p_partkey
    LEFT JOIN SupplierStats ss ON s.s_nationkey = ss.s_nationkey
    GROUP BY r.r_name, n.n_name
)
SELECT 
    RegionName,
    NationName,
    TotalParts,
    TotalSuppliers,
    TotalSupplyCost,
    AvgPartNameLength,
    AvgSupplierAccountBalance
FROM CombinedResults
ORDER BY RegionName, NationName;
