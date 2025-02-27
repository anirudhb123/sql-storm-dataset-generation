WITH RecursiveOrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS segment_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, p.p_partkey
),
NationRegionSummary AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(ros.total_revenue) AS total_revenue,
    AVG(spd.supply_cost) AS avg_supply_cost_per_part
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RecursiveOrderSummary ros ON n.n_nationkey IN (
        SELECT DISTINCT s.s_nationkey 
        FROM supplier s 
        WHERE s.s_suppkey IN (
            SELECT sp.s_suppkey 
            FROM SupplierPartDetails sp 
            WHERE sp.total_parts > 0 
        )
    )
LEFT JOIN 
    SupplierPartDetails spd ON spd.total_parts > 0 
WHERE 
    n.n_nationkey IS NOT NULL 
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
