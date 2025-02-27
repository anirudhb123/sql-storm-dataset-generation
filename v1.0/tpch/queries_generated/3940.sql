WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
),
SupplierTotalCost AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE 
        l.l_shipdate >= DATE '2022-01-01' 
        AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    n.n_name, 
    r.r_name, 
    COALESCE(SUM(stc.total_cost), 0) AS total_spent,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    AVG(ro.o_totalprice) AS avg_order_value
FROM 
    nation n
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierTotalCost stc ON s.s_suppkey = stc.ps_suppkey
LEFT JOIN 
    RankedOrders ro ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                        FROM partsupp ps 
                                        WHERE ps.ps_partkey IN (SELECT l.l_partkey 
                                                                FROM lineitem l 
                                                                WHERE l.l_orderkey = ro.o_orderkey)
                                        LIMIT 1)
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 0
ORDER BY 
    total_spent DESC, 
    avg_order_value DESC;
