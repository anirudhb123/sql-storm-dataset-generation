WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.c_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
),
OrderLineDetails AS (
    SELECT 
        hvo.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(li.l_linenumber) AS item_count
    FROM 
        HighValueOrders hvo
    JOIN 
        lineitem li ON hvo.o_orderkey = li.l_orderkey
    GROUP BY 
        hvo.o_orderkey
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.c_name,
    old.total_revenue,
    old.item_count,
    r.r_name AS region_name
FROM 
    HighValueOrders hvo
JOIN 
    supplier s ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        JOIN lineitem li ON li.l_partkey = p.p_partkey 
        WHERE li.l_orderkey = hvo.o_orderkey 
        LIMIT 1
    )
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    OrderLineDetails old ON hvo.o_orderkey = old.o_orderkey
ORDER BY 
    old.total_revenue DESC;
