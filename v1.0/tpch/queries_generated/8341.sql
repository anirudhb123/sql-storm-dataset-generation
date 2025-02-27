WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.c_acctbal
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    t.c_name,
    s.total_availqty,
    s.avg_supplycost,
    CASE 
        WHEN t.o_totalprice > 1000 THEN 'High Value'
        WHEN t.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    TopOrders t
JOIN 
    SupplierStats s ON s.ps_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE 
            l.l_orderkey = t.o_orderkey
    )
ORDER BY 
    t.o_orderdate DESC,
    t.o_totalprice DESC;
