WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierPartPricing AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_brand,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2021-01-01' AND 
        l.l_shipdate <= '2021-12-31'
    GROUP BY 
        p.p_partkey, p.p_brand
    HAVING 
        total_sales > 10000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(sp.total_supply_cost) AS avg_supply_cost,
    SUM(hp.total_sales) AS total_part_sales
FROM 
    RankedOrders ro
LEFT JOIN 
    nation n ON ro.c_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierPartPricing sp ON sp.ps_partkey IN (SELECT p.p_partkey FROM HighValueParts hp WHERE hp.p_brand = 'Brand#12')
LEFT JOIN 
    HighValueParts hp ON hp.p_partkey = sp.ps_partkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 5
ORDER BY 
    total_part_sales DESC;
