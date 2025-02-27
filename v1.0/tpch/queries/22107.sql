WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
),
RankedOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        OrderSummary os
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(c.c_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    sd.s_name,
    sd.region_name,
    ns.n_name,
    ns.customer_count,
    ns.total_acctbal,
    ro.total_revenue,
    CASE 
        WHEN ro.revenue_rank IS NOT NULL THEN ro.revenue_rank
        ELSE 0
    END AS revenue_rank,
    COALESCE(sd.part_count, 0) AS parts_supplied
FROM 
    SupplierDetails sd
FULL OUTER JOIN 
    RankedOrders ro ON sd.s_suppkey = ro.o_orderkey
LEFT JOIN 
    NationSummary ns ON sd.region_name = ns.n_name
WHERE 
    (sd.s_acctbal > ALL (SELECT s_acctbal FROM supplier WHERE s_acctbal IS NOT NULL)
     OR sd.part_count IS NULL)
    AND (ro.total_revenue IS NOT NULL OR sd.s_name LIKE '%ACME%')
ORDER BY 
    sd.region_name, ns.customer_count DESC, ro.total_revenue ASC
LIMIT 100 OFFSET 10;
