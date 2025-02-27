WITH RECURSIVE OrderSums AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RegionSummary AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(sp.total_supplycost) AS total_cost
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
    GROUP BY 
        n.n_nationkey, r.r_name
)
SELECT 
    r.r_name,
    rs.supplier_count,
    COALESCE(rs.total_cost, 0) AS total_supply_cost,
    os.total_price AS order_total_price,
    CASE 
        WHEN os.rank = 1 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_status
FROM 
    RegionSummary rs
FULL OUTER JOIN 
    OrderSums os ON rs.supplier_count > 0
WHERE 
    (os.total_price > 1000 OR rs.total_supply_cost IS NULL)
ORDER BY 
    r.r_name, astotal_supply_cost DESC;
