
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
SignificantParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    INNER JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ps.total_cost) AS total_parts_cost
FROM 
    RankedOrders ro
INNER JOIN 
    customer c ON ro.c_name = c.c_name
INNER JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
INNER JOIN 
    region r ON n.n_regionkey = r.r_regionkey
INNER JOIN 
    SignificantParts ps ON ps.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = ro.o_orderkey
    )
WHERE 
    ro.rank_order <= 10
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    total_orders DESC, total_parts_cost DESC;
