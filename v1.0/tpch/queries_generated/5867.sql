WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderpriority
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
OrderDetails AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    hvo.o_orderpriority,
    COALESCE(od.revenue, 0) AS order_revenue,
    si.s_name,
    si.s_acctbal
FROM 
    HighValueOrders hvo
LEFT JOIN 
    OrderDetails od ON hvo.o_orderkey = od.l_orderkey
JOIN 
    SupplierInfo si ON si.ps_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_orderkey = hvo.o_orderkey
    )
ORDER BY 
    hvo.o_orderdate DESC, 
    hvo.o_totalprice DESC;
