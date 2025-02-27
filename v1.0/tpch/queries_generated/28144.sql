WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM part p
    WHERE p.p_retailprice > 100.00
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS SupplierTotal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
DetailedReport AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.p_retailprice,
        sc.SupplierTotal,
        co.TotalSpent,
        co.OrderCount
    FROM RankedParts rp
    LEFT JOIN SupplierCount sc ON rp.p_partkey = sc.ps_partkey
    LEFT JOIN CustomerOrders co ON co.TotalSpent > 1000.00
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_retailprice,
    d.SupplierTotal,
    d.TotalSpent,
    d.OrderCount
FROM part p
JOIN DetailedReport d ON p.p_partkey = d.p_partkey
WHERE d.SupplierTotal IS NOT NULL
ORDER BY d.TotalSpent DESC, p.p_retailprice ASC
LIMIT 10;
