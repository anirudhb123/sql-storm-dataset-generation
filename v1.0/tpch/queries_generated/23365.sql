WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL AND p.p_retailprice > 100
), 

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey, s.s_name
), 

HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) 
        AND o.o_orderdate >= '2023-01-01'
), 

CustomerPreferences AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 1
)

SELECT 
    cp.c_name,
    cp.order_count,
    rp.p_name,
    rp.p_retailprice,
    sd.total_supply_cost,
    CASE 
        WHEN rp.price_rank = 1 THEN 'Best Price'
        ELSE 'Regular Price'
    END AS price_status
FROM 
    CustomerPreferences cp
JOIN 
    HighValueOrders hvo ON cp.order_count > 5
JOIN 
    RankedParts rp ON rp.price_rank <= 5
LEFT JOIN 
    SupplierDetails sd ON sd.total_supply_cost > 5000
WHERE 
    cp.c_mktsegment IN (SELECT DISTINCT c_mktsegment FROM customer WHERE c_acctbal IS NOT NULL)
ORDER BY 
    cp.order_count DESC,
    rp.p_retailprice ASC
LIMIT 10;
