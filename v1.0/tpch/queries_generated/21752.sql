WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
    AND o.o_orderstatus IN ('O', 'P')
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY ps.ps_partkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 0
),
BizarreJoin AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(r.r_name, 'Unknown') AS RegionName,
        s.s_name,
        CASE 
            WHEN s.s_acctbal IS NULL OR s.s_acctbal < 0 THEN 'Negative Balance'
            WHEN s.s_acctbal BETWEEN 0 AND 500 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS BalanceStatus
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 500.00)
    OR p.p_comment LIKE '%special%'
)
SELECT 
    bo.p_partkey,
    bo.p_name,
    bo.RegionName,
    bo.s_name,
    bo.BalanceStatus,
    COALESCE(cs.OrderCount, 0) AS CustomerOrderCount,
    COALESCE(cs.TotalSpent, 0.00) AS TotalSpentByCustomer,
    r.o_orderkey AS HighValueOrderKey
FROM BizarreJoin bo
LEFT JOIN CustomerStats cs ON bo.p_partkey = (SELECT MIN(ps.ps_partkey) FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MAX(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = bo.p_partkey))
LEFT JOIN RankedOrders r ON bo.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = bo.p_partkey) AND ps.ps_availqty >= 10)
WHERE bo.p_partkey IS NOT NULL
ORDER BY bo.BalanceStatus, cs.TotalSpent DESC;
