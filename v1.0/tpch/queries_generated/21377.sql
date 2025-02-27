WITH SupplyCost AS (
    SELECT 
        ps_partkey, 
        ps_suppkey,
        ps_availqty, 
        ps_supplycost,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS cost_rank
    FROM 
        partsupp
), 
RegionNation AS (
    SELECT 
        n.n_nationkey,
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
        n.n_nationkey, n.n_name, r.r_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(l.l_returnflag) FILTER (WHERE l.l_returnflag = 'R') AS return_count,
        COUNT(DISTINCT l.l_linenumber) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    SUM(CASE 
        WHEN od.total_revenue IS NULL THEN 0 
        ELSE od.total_revenue END) AS total_revenue,
    AVG(od.avg_quantity) AS average_quantity,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    COUNT(DISTINCT sc.ps_partkey) AS distinct_parts,
    MAX(CASE 
        WHEN sc.cost_rank = 1 THEN sc.ps_supplycost 
        ELSE NULL END) AS lowest_supplycost,
    CASE 
        WHEN COUNT(od.o_orderkey) > 0 THEN 
            SUM(od.return_count) * 100.0 / COUNT(od.o_orderkey)
        ELSE 0 
    END AS return_rate_percentage
FROM 
    RegionNation r
LEFT JOIN 
    OrderDetails od ON r.n_nationkey = od.o_custkey
LEFT JOIN 
    SupplyCost sc ON sc.ps_partkey = od.o_custkey
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT od.o_orderkey) > 2
ORDER BY 
    AVG(od.avg_quantity) DESC, return_rate_percentage ASC;
