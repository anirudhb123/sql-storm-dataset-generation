WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= date '2023-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) as supplied_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.region_name,
    SUM(lo.total_order_value) AS total_value,
    SUM(COALESCE(ss.total_supply_cost, 0)) AS total_supply_cost,
    COUNT(DISTINCT ss.s_suppkey) AS unique_suppliers
FROM 
    RankedOrders lo
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = lo.o_custkey)
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierSummary ss ON lo.o_orderkey = ss.s_suppkey
WHERE 
    lo.rank <= 10
GROUP BY 
    r.region_name
HAVING 
    SUM(lo.total_order_value) > 1000
ORDER BY 
    total_value DESC;
