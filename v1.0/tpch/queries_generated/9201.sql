WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
    ORDER BY 
        total_sales DESC
    LIMIT 5
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.c_name,
    ro.c_acctbal,
    tn.n_name,
    sc.total_supply_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    TopNations tn ON ro.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        JOIN 
            partsupp ps ON l.l_partkey = ps.ps_partkey
        JOIN 
            supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE 
            s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = tn.n_name)
    )
LEFT JOIN 
    SupplierCost sc ON ro.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey IN (
                SELECT ps_partkey FROM partsupp
            )
    )
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_totalprice DESC;
