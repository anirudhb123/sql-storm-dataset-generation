WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < '2023-01-01')
),
FilteredLineitems AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_suppkey, 
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        CASE 
            WHEN l.l_returnflag = 'R' THEN SUM(l.l_extendedprice * l.l_discount)
            ELSE NULL
        END AS return_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_returnflag
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey, 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_name, r.r_name
)
SELECT 
    CASE 
        WHEN SUM(lo.total_revenue) IS NULL THEN 'No Revenue'
        ELSE SUM(lo.total_revenue)::varchar
    END AS total_revenue,
    COUNT(DISTINCT so.s_suppkey) AS supplier_count,
    rg.region_name,
    FR.total_quantity
FROM 
    RankedOrders ro
LEFT JOIN 
    FilteredLineitems lo ON ro.o_orderkey = lo.l_orderkey
FULL OUTER JOIN 
    SupplierRegion sr ON sr.part_count > 5
JOIN 
    (SELECT DISTINCT n_name, r_name FROM SupplierRegion) rg ON rg.n_name = sr.nation_name
WHERE 
    ro.o_orderdate BETWEEN '2022-01-01' AND '2023-01-01'
GROUP BY 
    rg.region_name, ro.o_orderdate, FR.total_quantity
HAVING 
    COUNT(DISTINCT lo.l_partkey) > 10 OR MAX(ro.order_rank) = 1
ORDER BY 
    total_revenue DESC NULLS LAST;
