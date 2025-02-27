WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 10
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supplier_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CombinedData AS (
    SELECT 
        to.o_orderkey,
        to.o_orderstatus,
        to.total_revenue,
        sr.s_name,
        sr.total_supplier_cost
    FROM 
        TopOrders to
    LEFT JOIN 
        SupplierRevenue sr ON to.o_orderstatus = 'F'
)
SELECT 
    c.c_name,
    c.c_acctbal,
    cd.o_orderkey,
    cd.total_revenue,
    cd.s_name,
    cd.total_supplier_cost
FROM 
    customer c
JOIN 
    CombinedData cd ON cd.o_orderstatus = 'F' AND c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderstatus = cd.o_orderstatus)
WHERE 
    c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
ORDER BY 
    cd.total_revenue DESC, c.c_name ASC;
