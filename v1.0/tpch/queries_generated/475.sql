WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.n_name AS nation_name,
    ns.r_name AS region_name,
    ss.s_name AS supplier_name,
    os.total_order_value,
    ss.total_available_quantity,
    ss.avg_supply_cost
FROM 
    NationRegion ns
LEFT JOIN 
    SupplierStats ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN 
    OrderStats os ON os.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey LIMIT 1)
WHERE 
    (ss.total_available_quantity IS NOT NULL OR os.total_order_value IS NOT NULL)
    AND EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 0 AND ps.ps_supplycost < 100
    )
ORDER BY 
    total_order_value DESC NULLS LAST
LIMIT 50;
