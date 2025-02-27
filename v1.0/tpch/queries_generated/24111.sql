WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS rn
    FROM 
        orders
    WHERE 
        o_orderstatus IN ('O', 'P')
),
CombinedData AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.rn <= 3
    GROUP BY 
        o.o_orderkey, c.c_name
),
FinalOutput AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(cd.total_revenue) AS avg_revenue,
        SUM(CASE WHEN cd.last_ship_date IS NULL THEN 1 ELSE 0 END) AS null_ship_dates
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        CombinedData cd ON ps.ps_partkey = cd.o_orderkey
    GROUP BY 
        r.r_name
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 0
)
SELECT 
    f.r_name,
    f.customer_count,
    f.avg_revenue,
    COALESCE(f.null_ship_dates, 0) AS null_ship_dates_count,
    STRING_AGG(DISTINCT CONCAT('Cust: ', f.customer_count, ' Avg: ', f.avg_revenue), '; ') AS customer_summary
FROM 
    FinalOutput f
WHERE 
    f.avg_revenue > 5000 OR f.null_ship_dates_count > 10
ORDER BY 
    f.avg_revenue DESC, f.customer_count ASC;
