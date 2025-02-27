WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
        CASE 
            WHEN o.o_orderstatus = 'O' AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O') 
            THEN 'High Value'
            ELSE 'Standard'
        END AS OrderType
    FROM orders o
),
SupplierSummary AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
CombinedData AS (
    SELECT 
        r.r_name,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
        COALESCE(cs.TotalSpent, 0) AS CustomerTotalSpent,
        cs.OrderCount,
        COALESCE(ss.TotalSupplyCost, 0) AS TotalSupplyCost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN CustomerOrderCounts cs ON cs.c_custkey = (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT od.o_orderkey FROM RankedOrders od WHERE od.rn = 1))
    LEFT JOIN SupplierSummary ss ON ss.ps_partkey = ps.ps_partkey
    GROUP BY r.r_name, n.n_name, cs.CustomerTotalSpent, cs.OrderCount
)
SELECT 
    r.r_name, 
    n.n_name,
    ROUND(SUM(CASE 
        WHEN cd.Revenue IS NULL AND cd.CustomerTotalSpent IS NOT NULL THEN cd.CustomerTotalSpent
        ELSE cd.Revenue
    END), 2) AS FinalRevenue,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS OrderStatus
FROM CombinedData cd
LEFT JOIN RankedOrders o ON o.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o.custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal IS NOT NULL))
GROUP BY r.r_name, n.n_name
HAVING FinalRevenue > 1000 OR OrderStatus = 'No Orders'
ORDER BY FinalRevenue DESC NULLS LAST;
