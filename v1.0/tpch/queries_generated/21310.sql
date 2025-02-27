WITH RankedSuppliers AS (
    SELECT 
        ps_suppkey,
        ps_partkey,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS RankCost,
        SUM(ps_availqty) OVER (PARTITION BY ps_partkey) AS TotalAvailable
    FROM 
        partsupp
    WHERE 
        ps_supplycost > 100
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        c.c_acctbal > 500 AND 
        o.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
),
HighValueLines AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice * (1 - l.l_discount) AS NetPrice
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
),
NationWiseAvg AS (
    SELECT 
        n.n_nationkey,
        AVG(l.NetPrice) AS AvgNetPrice
    FROM 
        HighValueLines l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(nwa.AvgNetPrice), 0) AS NationAvgNetPrice,
    COUNT(DISTINCT co.o_orderkey) AS TotalOrders,
    COUNT(DISTINCT rs.ps_suppkey) AS UniqueSuppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationWiseAvg nwa ON n.n_nationkey = nwa.n_nationkey
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus IN ('O', 'F')
    )
LEFT JOIN 
    RankedSuppliers rs ON rs.ps_partkey = ANY(
        SELECT DISTINCT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '30 day'
    )
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    NationAvgNetPrice DESC
LIMIT 10;
