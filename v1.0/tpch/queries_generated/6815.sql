WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplyDetails AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_retailprice,
    p.p_size,
    rs.order_date_range,
    cs.total_spent,
    cs.order_count,
    sd.supplier_count,
    sd.avg_supply_cost
FROM 
    part p
LEFT JOIN 
    (SELECT 
        ro.o_orderkey,
        MIN(ro.o_orderdate) AS order_date_range
     FROM 
        RankedOrders ro 
     GROUP BY 
        ro.o_orderkey
    ) rs ON p.p_partkey = rs.o_orderkey
LEFT JOIN 
    CustomerSummary cs ON cs.order_count > 5
LEFT JOIN 
    SupplyDetails sd ON sd.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 100.00
ORDER BY 
    cs.total_spent DESC, 
    sd.avg_supply_cost ASC
LIMIT 100;
