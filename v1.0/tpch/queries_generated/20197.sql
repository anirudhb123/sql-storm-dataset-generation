WITH RankedOrders AS (
    SELECT 
        o.orderkey,
        o.custkey,
        o.totalprice,
        SUM(l.quantity * (l.extendedprice * (1 - l.discount))) OVER (PARTITION BY o.orderkey) AS TotalLinePrice,
        ROW_NUMBER() OVER (PARTITION BY o.custkey ORDER BY o.orderdate DESC) AS OrderRank
    FROM orders o
    JOIN lineitem l ON o.orderkey = l.orderkey
    WHERE o.orderstatus IN ('F', 'O') 
      AND l.returnflag = 'N'
),
SupplierInfo AS (
    SELECT 
        s.suppkey,
        s.name,
        COALESCE(NULLIF(s.comment, ''), 'No comment provided') AS SafeComment,
        COUNT(DISTINCT ps.partkey) AS PartCount,
        AVG(ps.supplycost) AS AvgSupplyCost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.suppkey = ps.suppkey
    GROUP BY s.suppkey, s.name
),
TotalOrderValues AS (
    SELECT 
        ro.custkey,
        SUM(ro.TotalLinePrice) AS TotalCustomerSpend
    FROM RankedOrders ro
    WHERE ro.OrderRank <= 5
    GROUP BY ro.custkey
)
SELECT 
    r.r_name AS Region,
    COUNT(DISTINCT ni.n_nationkey) AS NationCount,
    SUM(tos.TotalCustomerSpend) AS TotalCustomerSpend,
    STRING_AGG(DISTINCT CONCAT(si.SafeComment, ' - Parts: ', si.PartCount), '; ') AS SupplierComments
FROM region r
JOIN nation ni ON r.r_regionkey = ni.n_regionkey
JOIN customer c ON c.nationkey = ni.n_nationkey
LEFT JOIN TotalOrderValues tos ON c.custkey = tos.custkey
LEFT JOIN SupplierInfo si ON ni.n_nationkey = si.suppkey
WHERE tos.TotalCustomerSpend IS NOT NULL OR si.PartCount > 0
GROUP BY r.r_name
HAVING COUNT(DISTINCT ni.n_nationkey) > 1
ORDER BY TotalCustomerSpend DESC NULLS LAST;
