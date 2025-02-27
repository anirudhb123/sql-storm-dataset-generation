WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as rnk
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
        ro.c_name,
        ro.c_acctbal
    FROM 
        RankedOrders ro
    WHERE 
        ro.rnk <= 10
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_retailprice,
        s.s_name,
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_container IN ('SM CASE', 'MED BOX', 'LARGE BOX')
),
OrderLineItems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(*) AS total_items
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.c_name,
    to.o_totalprice,
    sp.p_name,
    sp.p_retailprice,
    op.total_revenue,
    op.total_items
FROM 
    TopOrders to
JOIN 
    OrderLineItems op ON to.o_orderkey = op.l_orderkey
JOIN 
    SupplierParts sp ON sp.ps_partkey IN (SELECT li.l_partkey FROM lineitem li WHERE li.l_orderkey = to.o_orderkey)
ORDER BY 
    to.o_totalprice DESC, to.o_orderdate ASC;
