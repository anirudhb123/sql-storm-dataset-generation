WITH RECURSIVE PartCosts AS (
    SELECT 
        ps.partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.partkey
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name,
    COALESCE(ps.total_cost, 0) AS total_part_cost,
    rs.nation_count,
    rs.total_supplier_balance,
    os.o_orderkey,
    os.o_orderdate,
    os.net_revenue,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY os.net_revenue DESC) AS revenue_rank
FROM 
    region r
LEFT JOIN 
    RegionSummary rs ON r.r_regionkey = rs.r_regionkey
LEFT JOIN 
    PartCosts ps ON ps.partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost > 50)
LEFT JOIN 
    OrderSummary os ON rs.nation_count > 5
ORDER BY 
    r.r_name, os.net_revenue DESC;
