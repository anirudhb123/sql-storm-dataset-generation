WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
        AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, p.p_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.total_revenue) AS average_order_revenue,
    COALESCE(MAX(spd.total_avail_qty), 0) AS max_available_qty,
    MIN(spd.avg_supply_cost) AS min_avg_supply_cost
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
LEFT JOIN 
    SupplierPartDetails spd ON spd.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
    )
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
ORDER BY 
    total_orders DESC, average_order_revenue DESC
LIMIT 10;
