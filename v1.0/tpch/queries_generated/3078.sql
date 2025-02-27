WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
SuppliersWithParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    o.o_orderkey,
    o.o_totalprice,
    c.c_name,
    sr.region_name,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
FROM 
    RankedOrders o
LEFT JOIN 
    CustomerRegion sr ON o.o_custkey = sr.c_custkey
LEFT JOIN 
    SuppliersWithParts sp ON o.o_orderkey = sp.s_suppkey  -- Assuming a fictional link for example purposes
WHERE 
    o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
    AND sr.region_name IS NOT NULL
ORDER BY 
    price_rank, o.o_orderdate DESC;
