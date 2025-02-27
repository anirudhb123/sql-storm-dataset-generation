WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_custkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
),
SupplierStatistics AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
CustomerNationalRevenue AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    n.n_name,
    COALESCE(r.total_revenue, 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders,
    SUM(s.total_available) AS total_available_parts,
    AVG(s.average_cost) AS average_part_cost
FROM 
    nation n
LEFT JOIN 
    CustomerNationalRevenue r ON n.n_nationkey = r.c_nationkey
LEFT JOIN 
    RankedOrders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN 
    SupplierStatistics s ON s.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey))
GROUP BY 
    n.n_name
HAVING 
    SUM(r.total_revenue) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'F' AND o_orderdate < DATEADD(month, -6, GETDATE()))
ORDER BY 
    total_revenue DESC, n.n_name
OPTION (MAXDOP = 1);
