WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders AS o
),
SupplierCost AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost) as TotalSupplyCost
    FROM partsupp AS ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost) > 1000
),
CustomerBalance AS (
    SELECT c.c_custkey, SUM(c.c_acctbal) as TotalBalance
    FROM customer AS c
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
    HAVING SUM(c.c_acctbal) < 5000
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(s.s_name, 'Unknown Supplier') AS SupplierName, 
    lb.TotalBalance AS CustomerBalance, 
    CASE 
        WHEN lb.TotalBalance IS NULL THEN 'No Balance'
        ELSE 'Has Balance'
    END AS BalanceStatus,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS AvgPrice,
    STRING_AGG(DISTINCT r.r_name, ', ') AS Regions
FROM part AS p
LEFT OUTER JOIN (
    SELECT l.l_partkey, l.l_suppkey, l.l_orderkey, l.l_discount, l.l_extendedprice
    FROM lineitem AS l
    JOIN RankedOrders AS ro ON l.l_orderkey = ro.o_orderkey
    WHERE ro.OrderRank <= 3
) AS l ON p.p_partkey = l.l_partkey
LEFT JOIN supplier AS s ON l.l_suppkey = s.s_suppkey
LEFT JOIN CustomerBalance AS lb ON s.s_suppkey = lb.c_custkey
LEFT JOIN partsupp AS ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN nation AS n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region AS r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 1 AND 10 AND 
    (p.p_retailprice < 50.00 OR p.p_container IS NULL) AND 
    EXISTS (
        SELECT 1 
        FROM SupplierCost AS sc 
        WHERE sc.ps_partkey = ps.ps_partkey AND sc.TotalSupplyCost BETWEEN 1000 AND 5000
    )
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    lb.TotalBalance 
HAVING 
    COUNT(l.l_orderkey) > 2
ORDER BY 
    AvgPrice DESC;
