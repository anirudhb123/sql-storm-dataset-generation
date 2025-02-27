WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierAggregation AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    INNER JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No balance'
            ELSE CAST(c.c_acctbal AS varchar)
        END AS balance_status
    FROM 
        customer c
    WHERE 
        c.c_mktsegment = 'BUILDING'
),
ItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    ARRAY_AGG(DISTINCT fp.c_name) AS customer_names,
    SUM(ia.total_revenue) AS total_revenue,
    AVG(sa.average_supply_cost) AS avg_supply_cost,
    MAX(ia.distinct_parts) AS max_distinct_parts_order
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierAggregation sa ON s.s_suppkey = sa.ps_suppkey
LEFT JOIN 
    FilteredCustomers fp ON s.s_nationkey = fp.c_nationkey
LEFT JOIN 
    ItemAnalysis ia ON ia.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders o WHERE o.o_orderdate < CURRENT_DATE - INTERVAL '30 DAY')
WHERE 
    (sa.total_available_quantity IS NULL OR sa.total_available_quantity > 100)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT fp.c_custkey) > 5 AND MAX(ia.max_distinct_parts_order) > 1
ORDER BY 
    total_revenue DESC;
