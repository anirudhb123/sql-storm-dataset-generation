WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
RecentOrderDetails AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        p.p_name,
        s.s_name,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax
    FROM RankedOrders ro
    JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ro.rnk = 1
),
AggregatedData AS (
    SELECT 
        rd.o_orderkey,
        COUNT(DISTINCT rd.s_name) AS distinct_suppliers,
        SUM(rd.l_extendedprice) AS total_revenue,
        AVG(rd.l_quantity) AS avg_quantity,
        SUM(rd.l_tax) AS total_tax
    FROM RecentOrderDetails rd
    GROUP BY rd.o_orderkey
)
SELECT 
    ad.o_orderkey,
    ad.distinct_suppliers,
    ad.total_revenue,
    ad.avg_quantity,
    ad.total_tax,
    nt.n_name AS nation_name,
    rg.r_name AS region_name
FROM AggregatedData ad
JOIN customer c ON ad.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN nation nt ON c.c_nationkey = nt.n_nationkey
JOIN region rg ON nt.n_regionkey = rg.r_regionkey
ORDER BY ad.total_revenue DESC
LIMIT 10;
