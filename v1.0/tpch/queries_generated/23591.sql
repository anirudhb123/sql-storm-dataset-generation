WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20 
        AND p.p_retailprice IS NOT NULL
),
AggregateSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_total,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus <> 'F'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
NationRegion AS (
    SELECT 
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    np.r_name,
    SUM(np.total_supply_cost) AS total_supply_costs,
    COUNT(DISTINCT np.supplier_count) AS unique_suppliers,
    AVG(fo.net_total) AS avg_order_value
FROM 
    (SELECT 
         r.r_name, 
         asu.total_supply_cost, 
         n.supplier_count
     FROM 
         AggregateSuppliers asu
     JOIN 
         RankedParts rp ON rp.p_partkey = asu.ps_partkey
     LEFT JOIN 
         NationRegion n ON n.supplier_count > 0
     LEFT JOIN 
         region r ON r.r_name = n.r_name) np
LEFT JOIN 
    FilteredOrders fo ON np.total_supply_cost > 1000
WHERE 
    np.supplier_count IS NOT NULL
GROUP BY 
    np.r_name 
HAVING 
    COUNT(np.total_supply_cost) > 5
ORDER BY 
    np.r_name 
FETCH FIRST 10 ROWS ONLY;
