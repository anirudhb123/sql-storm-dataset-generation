
WITH PartSupplierAggregation AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
OrderStatistics AS (
    SELECT 
        l.l_partkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    psa.total_avail_qty,
    psa.avg_supply_cost,
    psa.supplier_names,
    os.total_orders,
    os.total_quantity,
    os.total_revenue,
    CONCAT('Part ', p.p_name, ' from brand ', p.p_brand, ' has ordered ', COALESCE(os.total_orders, 0), ' times and is supplied by ', COALESCE(psa.supplier_names, 'None')) AS order_summary
FROM 
    part p
LEFT JOIN 
    PartSupplierAggregation psa ON p.p_partkey = psa.ps_partkey
LEFT JOIN 
    OrderStatistics os ON p.p_partkey = os.l_partkey
WHERE 
    p.p_retailprice > 100.00
ORDER BY 
    COALESCE(os.total_revenue, 0) DESC
LIMIT 10;
