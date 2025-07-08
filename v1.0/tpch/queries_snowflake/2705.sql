
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
        AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    COALESCE(s.total_suppliers, 0) AS total_suppliers,
    COALESCE(s.total_cost, 0) AS total_cost,
    COALESCE(d.revenue, 0) AS revenue,
    COALESCE(d.distinct_parts, 0) AS distinct_parts
FROM 
    RankedOrders r
LEFT JOIN 
    (SELECT n.n_nationkey, s.s_suppkey
     FROM nation n 
     JOIN supplier s ON n.n_nationkey = s.s_nationkey) AS joined_suppliers 
    ON joined_suppliers.s_suppkey = r.o_orderkey
LEFT JOIN 
    SupplierStats s ON s.s_nationkey = joined_suppliers.n_nationkey
LEFT JOIN 
    OrderDetails d ON r.o_orderkey = d.l_orderkey
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_totalprice DESC,
    r.o_orderdate ASC
LIMIT 50;
