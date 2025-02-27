WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
    GROUP BY 
        s.s_suppkey
),
CustomerAvgOrder AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS avg_order
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(SS.total_supply_cost, 0) AS total_supply_cost,
    CA.avg_order,
    COUNT(DISTINCT LO.l_orderkey) AS total_orders,
    SUM(LO.l_extendedprice * (1 - LO.l_discount)) AS total_revenue
FROM 
    part p
LEFT JOIN 
    partsupp PS ON PS.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON PS.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem LO ON LO.l_partkey = p.p_partkey
LEFT JOIN 
    SupplierStats SS ON s.s_suppkey = SS.s_suppkey
LEFT JOIN 
    CustomerAvgOrder CA ON CA.c_custkey = (
        SELECT 
            c.c_custkey
        FROM 
            customer c
        JOIN 
            orders o ON c.c_custkey = o.o_custkey
        WHERE 
            o.o_orderkey = LO.l_orderkey
        LIMIT 1
    )
WHERE 
    p.p_retailprice > (
        SELECT 
            AVG(p2.p_retailprice) 
        FROM 
            part p2
        WHERE 
            p2.p_brand = p.p_brand
    )
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, CA.avg_order, SS.total_supply_cost
ORDER BY 
    total_revenue DESC, p.p_name
LIMIT 10;