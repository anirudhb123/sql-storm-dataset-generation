WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), CustomerRegions AS (
    SELECT 
        c.c_custkey,
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, r.r_name
), TotalDiscounts AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * l.l_discount) AS total_discount
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.1
    GROUP BY 
        l.l_orderkey
), FinalData AS (
    SELECT 
        cr.r_name,
        coalesce(SP.total_supply_cost, 0) AS total_supply_cost,
        coalesce(TO.total_discount, 0) AS total_discount,
        COUNT(DISTINCT ro.o_orderkey) AS order_count
    FROM 
        CustomerRegions cr
    LEFT JOIN 
        SupplierParts SP ON cr.c_custkey = SP.ps_partkey
    LEFT JOIN 
        TotalDiscounts TO ON cr.c_custkey = TO.l_orderkey
    JOIN 
        RankedOrders ro ON cr.order_count = ro.rn
    GROUP BY 
        cr.r_name, SP.total_supply_cost, TO.total_discount
)
SELECT 
    r_name,
    total_supply_cost,
    total_discount,
    order_count,
    CASE 
        WHEN total_discount > total_supply_cost THEN 'High Discount'
        ELSE 'Normal Discount'
    END AS discount_category
FROM 
    FinalData
WHERE 
    r_name IS NOT NULL
ORDER BY 
    total_supply_cost DESC, total_discount ASC;
