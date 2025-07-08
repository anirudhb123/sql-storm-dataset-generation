WITH PriceSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(p.p_retailprice) AS avg_retail_price,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierDetail AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
OrderTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_supply_cost,
    ps.avg_retail_price,
    sd.s_name AS top_supplier_name,
    sd.nation_name,
    sd.region_name,
    ot.total_order_value,
    CASE 
        WHEN ps.total_supply_cost > ps.avg_retail_price THEN 'Costly Supply'
        ELSE 'Affordable Supply'
    END AS supply_status
FROM 
    PriceSummary ps
LEFT JOIN 
    SupplierDetail sd ON sd.rank = 1 
LEFT JOIN 
    OrderTotals ot ON ot.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_partkey = ps.p_partkey 
        ORDER BY l.l_shipdate DESC 
        LIMIT 1
    )
WHERE 
    ps.supplier_count > 1 
    AND sd.s_acctbal IS NOT NULL
ORDER BY 
    ps.total_supply_cost DESC, 
    ps.avg_retail_price ASC;
