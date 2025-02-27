WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.rnk <= 10
),
SupplierReport AS (
    SELECT
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name,
    sr.s_name,
    sr.total_supply_value
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
JOIN 
    SupplierReport sr ON l.l_partkey = sr.ps_partkey
WHERE 
    sr.total_supply_value > (
        SELECT AVG(total_supply_value) FROM SupplierReport
    )
ORDER BY 
    to.o_orderdate DESC, to.o_totalprice DESC;
