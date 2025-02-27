WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
),
SupplierAvg AS (
    SELECT 
        ps.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
    HAVING 
        avg_supplycost > 100.00
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        order_count > 10
),
ComplexLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status,
        COUNT(*) OVER (PARTITION BY l.l_orderkey) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        l.l_orderkey, l.l_returnflag
)
SELECT 
    r.r_name,
    COUNT(DISTINCT r.r_regionkey) AS region_count,
    SUM(COALESCE(c.max_order_value, 0)) AS total_max_order_value,
    SUM(cl.net_revenue) AS total_net_revenue,
    MAX(s.avg_supplycost) AS highest_avg_supplycost
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierAvg sa ON s.s_suppkey = sa.s_suppkey
LEFT JOIN 
    CustomerOrders c ON c.c_custkey = ANY (SELECT DISTINCT o.o_custkey FROM RankedOrders ro JOIN orders o ON o.o_orderkey = ro.o_orderkey WHERE order_rank <= 10)
LEFT JOIN 
    ComplexLineItems cl ON cl.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
WHERE 
    r.r_name IS NOT NULL 
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_net_revenue DESC, region_count ASC;
