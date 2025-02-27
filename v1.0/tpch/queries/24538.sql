WITH RECURSIVE RegionalTrends AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name as region_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
    HAVING 
        SUM(ps.ps_supplycost) > (
            SELECT 
                AVG(ps_inner.ps_supplycost) 
            FROM 
                partsupp ps_inner
            JOIN 
                supplier s_inner ON ps_inner.ps_suppkey = s_inner.s_suppkey
            WHERE 
                s_inner.s_nationkey = n.n_nationkey
        )
    UNION ALL
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        rt.total_supply_cost * 1.1 AS total_supply_cost
    FROM 
        regionaltrends rt
    JOIN 
        nation n ON rt.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rt.total_supply_cost * 1.1 < (
            SELECT 
                MAX(ps.ps_supplycost) 
            FROM 
                partsupp ps
            JOIN 
                supplier s ON ps.ps_suppkey = s.s_suppkey
            WHERE 
                s.s_nationkey = n.n_nationkey
        )
),
NationalStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    rt.region_name,
    ns.n_name,
    ns.supplier_count,
    ns.avg_account_balance,
    ns.total_sales,
    ROW_NUMBER() OVER (PARTITION BY rt.region_name ORDER BY ns.total_sales DESC) AS rank,
    CASE 
        WHEN ns.total_sales IS NULL THEN 'No Sales'
        WHEN ns.total_sales > 10000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    NationalStats ns
JOIN 
    RegionalTrends rt ON ns.n_name = rt.n_name
WHERE 
    rt.total_supply_cost IS NOT NULL
ORDER BY 
    rt.region_name, rank;
