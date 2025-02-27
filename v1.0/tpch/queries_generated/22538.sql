WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS part_rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > (SELECT AVG(p_size) FROM part)
    GROUP BY 
        ps.ps_partkey, p.p_name, p.p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 0
)
SELECT 
    r.r_name,
    SUM(COALESCE(cp.order_count, 0)) AS total_customer_orders,
    SUM(sp.total_supply_cost) AS total_supply_cost,
    COUNT(DISTINCT ro.o_orderkey) AS unique_orders,
    STRING_AGG(DISTINCT p.p_name, ', ') AS featured_parts
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON s.s_suppkey = sp.ps_partkey
LEFT JOIN 
    CustomerOrders cp ON s.s_suppkey = cp.c_custkey
LEFT JOIN 
    RankedOrders ro ON cp.c_custkey = ro.o_orderkey
WHERE 
    r.r_name IS NOT NULL
    AND (ro.o_orderdate >= DATE '2023-01-01' OR ro.o_orderdate IS NULL)
    AND (sp.part_rank <= 3 OR sp.part_rank IS NULL)
GROUP BY 
    r.r_name
ORDER BY 
    total_customer_orders DESC,
    total_supply_cost DESC
LIMIT 10;
