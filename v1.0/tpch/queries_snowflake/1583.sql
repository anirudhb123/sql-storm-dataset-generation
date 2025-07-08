
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierPartPrices AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    COALESCE(s.avg_supplycost, 0) AS avg_supply_cost,
    COALESCE(h.total_value, 0) AS order_value,
    CASE 
        WHEN r.o_totalprice > 1000 THEN 'High Value'
        WHEN r.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierPartPrices s ON s.ps_partkey = (
        SELECT 
            l.l_partkey
        FROM 
            lineitem l
        WHERE 
            l.l_orderkey = r.o_orderkey
        LIMIT 1
    )
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey = r.o_orderkey
WHERE 
    r.rn <= 5
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;
