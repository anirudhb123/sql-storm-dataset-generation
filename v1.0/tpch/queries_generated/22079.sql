WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        o.o_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
HighValueOrders AS (
    SELECT DISTINCT 
        o.o_orderkey, 
        o.o_totalprice, 
        c.c_custkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
NationRegion AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(nr.nation_name, 'Unknown') AS nation_name,
    COALESCE(nr.region_name, 'Unknown Region') AS region_name,
    hs.total_supply_cost,
    cs.order_count,
    cs.avg_order_value,
    CASE 
        WHEN hs.total_supply_cost IS NULL THEN 'No Supply Cost'
        ELSE 'Has Supply Cost'
    END AS supply_cost_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers hs ON ps.ps_suppkey = hs.s_suppkey
LEFT JOIN 
    CustomerOrderStats cs ON cs.o_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT o_orderkey FROM HighValueOrders))
LEFT JOIN 
    NationRegion nr ON nr.supplier_count > 1
WHERE 
    (hs.rnk = 1 OR hs.rnk IS NULL)
    AND (cs.order_count IS NULL OR cs.avg_order_value > 1000)
ORDER BY 
    p.p_partkey DESC NULLS LAST;
