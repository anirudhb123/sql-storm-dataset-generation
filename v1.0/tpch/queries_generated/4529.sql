WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
),
RecentOrders AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM 
        lineitem lo
    JOIN 
        RankedOrders ro ON lo.l_orderkey = ro.o_orderkey
    WHERE 
        ro.rank <= 10
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    pn.p_partkey,
    pn.p_name,
    pn.p_brand,
    ps.total_supplier_cost,
    nations.n_name,
    COALESCE(ro.total_revenue, 0) AS order_revenue
FROM 
    part pn
LEFT JOIN 
    SupplierStats ps ON pn.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier))
LEFT JOIN 
    TopNations nations ON pn.p_container = nations.n_name
LEFT JOIN 
    RecentOrders ro ON ro.l_orderkey = (SELECT max(l_orderkey) FROM lineitem WHERE l_partkey = pn.p_partkey)
WHERE 
    pn.p_retailprice > 20.00
ORDER BY 
    order_revenue DESC, ps.total_supplier_cost ASC;
