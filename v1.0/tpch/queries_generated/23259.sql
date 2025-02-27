WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 1000
),
CustomerWithAverages AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        AVG(o.o_totalprice) BETWEEN 100 AND 1000
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_container
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2
            WHERE p2.p_size = p.p_size
        )
),
FinalOutput AS (
    SELECT 
        cp.custkey,
        cp.c_name,
        p.p_name,
        sp.total_available_quantity,
        sp.average_cost,
        ro.o_orderdate,
        CASE 
            WHEN sp.average_cost IS NULL THEN 'No Price'
            ELSE ROUND(sp.average_cost + (sp.average_cost * 0.2), 2)
        END AS adjusted_cost
    FROM 
        CustomerWithAverages cp
    LEFT JOIN 
        FilteredParts p ON p.p_partkey IN (SELECT ps.ps_partkey FROM SupplierParts sp WHERE sp.total_available_quantity > 500)
    LEFT JOIN 
        SupplierParts sp ON sp.ps_partkey = p.p_partkey
    LEFT JOIN 
        RankedOrders ro ON ro.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey AND ro.rn = 1)
    WHERE 
        sp.average_cost < cp.avg_order_value
)
SELECT 
    c.custkey,
    c.c_name,
    COALESCE(SUM(f.adjusted_cost), 0) AS total_adjusted_cost,
    COUNT(DISTINCT f.o_orderdate) AS order_dates_count
FROM 
    CustomerWithAverages c
LEFT JOIN 
    FinalOutput f ON f.custkey = c.c_custkey
GROUP BY 
    c.custkey, c.c_name
HAVING 
    SUM(f.adjusted_cost) > 5000 OR COUNT(DISTINCT f.o_orderdate) > 5
ORDER BY 
    total_adjusted_cost DESC, c.c_name;
