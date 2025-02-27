
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        s.s_name AS supplier_name,
        sp.TotalSupplyValue
    FROM 
        part p
    JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    LEFT JOIN 
        supplier s ON s.s_suppkey = (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey 
            ORDER BY ps.ps_supplycost DESC
            LIMIT 1
        )
    WHERE 
        sp.TotalSupplyValue > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
),
LatestOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS RecentOrder
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    R.c_name AS customer_name,
    H.p_name AS part_name,
    H.p_retailprice,
    L.o_orderkey,
    L.o_orderdate,
    L.o_totalprice
FROM 
    LatestOrders L
JOIN 
    RankedOrders R ON L.o_orderkey = R.o_orderkey
JOIN 
    HighValueParts H ON H.TotalSupplyValue > (
        SELECT MAX(ps_total) 
        FROM (
            SELECT SUM(ps_supplycost * ps_availqty) AS ps_total 
            FROM partsupp 
            GROUP BY ps_partkey
        ) AS t
    )
WHERE 
    R.OrderRank <= 5
ORDER BY 
    L.o_orderdate DESC, H.p_name;
