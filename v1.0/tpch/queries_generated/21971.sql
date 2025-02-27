WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank_within_segment
    FROM 
        customer c
),
SupplierPartData AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_value
    FROM 
        partsupp ps
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
),
EligibleOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
        AND o.o_orderstatus IN ('O', 'P')
),
FinalOutput AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COALESCE(SUM(spd.total_value) / NULLIF(SUM(spd.total_value) FILTER (WHERE spd.s_name IS NOT NULL), 0), 1) AS part_average,
        AVG(RC.c_acctbal) FILTER(WHERE RC.rank_within_segment <= 10) AS top_customer_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        SupplierPartData spd ON EXISTS (
            SELECT 1
            FROM partsupp ps
            WHERE ps.ps_partkey = spd.ps_partkey AND ps.ps_suppkey IN (
                SELECT s.s_suppkey
                FROM supplier s
                WHERE s.s_nationkey = n.n_nationkey
            )
        )
    LEFT JOIN 
        RankedCustomers RC ON n.n_nationkey = RC.c_nationkey
    GROUP BY 
        r.region_name, n.n_name
)
SELECT 
    f.region_name,
    f.nation_name,
    CASE WHEN f.part_average IS NULL THEN 'No Data' ELSE CAST(f.part_average AS VARCHAR) END AS avg_part_value,
    CASE WHEN f.top_customer_balance IS NULL THEN 'No Top Customers' ELSE CAST(f.top_customer_balance AS VARCHAR) END AS avg_top_customer_balance
FROM 
    FinalOutput f 
WHERE 
    f.part_average IS NOT NULL OR f.top_customer_balance IS NOT NULL
ORDER BY 
    f.region_name, f.nation_name DESC;
