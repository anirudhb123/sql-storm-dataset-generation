WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopCustomers AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank <= 5
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
LineItemMetrics AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(li.l_linenumber) AS total_line_items
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    tc.o_orderkey,
    tc.o_orderdate,
    tc.o_totalprice,
    tc.c_name,
    tc.nation_name,
    lm.total_revenue,
    lm.total_line_items,
    sd.s_name,
    sd.s_acctbal
FROM 
    TopCustomers tc
LEFT JOIN 
    LineItemMetrics lm ON tc.o_orderkey = lm.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON sd.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_name LIKE 'Supplier%'))
ORDER BY 
    tc.o_orderdate DESC, 
    tc.o_totalprice DESC;
