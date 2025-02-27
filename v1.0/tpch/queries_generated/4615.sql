WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2
        )
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    COALESCE(hvp.p_name, 'No High Value Part') AS high_value_part,
    COALESCE(s.total_supply_cost, 0) AS supplier_total_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueParts hvp ON l.l_partkey = hvp.p_partkey
LEFT JOIN 
    SupplierCost s ON hvp.p_partkey = s.ps_partkey
WHERE 
    ro.rank <= 5
    AND ro.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
ORDER BY 
    ro.o_totalprice DESC, 
    ro.o_orderkey;
