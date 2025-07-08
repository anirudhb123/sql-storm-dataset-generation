
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.c_name,
        ro.o_totalprice,
        COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_lineitem_value
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE 
        ro.order_rank <= 5
    GROUP BY 
        ro.o_orderkey, ro.c_name, ro.o_totalprice
)
SELECT 
    r.r_name,
    nv.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN ho.total_lineitem_value > 1000 THEN 1 ELSE 0 END) AS high_value_order_count,
    AVG(ss.avg_supply_cost) AS average_supply_cost
FROM 
    region r
JOIN 
    nation nv ON r.r_regionkey = nv.n_regionkey
JOIN 
    supplier s ON nv.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.ps_partkey
LEFT JOIN 
    HighValueOrders ho ON ho.o_orderkey IN (
        SELECT DISTINCT o.o_orderkey 
        FROM orders o 
        JOIN customer c ON o.o_custkey = c.c_custkey 
        WHERE c.c_nationkey = nv.n_nationkey
    )
JOIN 
    customer c ON c.c_nationkey = nv.n_nationkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, nv.n_name
ORDER BY 
    customer_count DESC;
