WITH Supplier_Aggregate AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Sales_Summary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        c.c_mktsegment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
),
Nation_Region_Summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    s.s_suppkey,
    s.s_name,
    sa.total_supply_cost,
    sa.unique_parts,
    ss.total_sales,
    ss.order_count,
    nrs.region_name,
    nrs.customer_count
FROM 
    Supplier_Aggregate sa
JOIN 
    Sales_Summary ss ON sa.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l))
JOIN 
    Nation_Region_Summary nrs ON nrs.customer_count > 0
ORDER BY 
    sa.total_supply_cost DESC, ss.total_sales DESC
LIMIT 10;
