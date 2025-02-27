WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerTotalOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(c.total_order_value) AS total_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        CustomerTotalOrders c ON n.n_nationkey = c.c_custkey
    GROUP BY 
        r.r_regionkey, r.r_name
    ORDER BY 
        total_value DESC
    LIMIT 5
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    ss.total_supply_cost,
    tr.total_value AS region_total_value
FROM 
    part p
JOIN 
    SupplierCosts ss ON ss.s_suppkey = p.p_partkey
JOIN 
    TopRegions tr ON tr.r_regionkey = (
        SELECT r.r_regionkey
        FROM nation n
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        WHERE s.s_suppkey = ss.s_suppkey
        LIMIT 1
    )
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    ss.total_supply_cost DESC, p.p_name;
