WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > DATE '2022-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    od.total_lineitem_value,
    COALESCE(sc.total_supplycost, 0) AS total_supplycost,
    COALESCE(ts.total_available, 0) AS total_available
FROM 
    RankedOrders o
LEFT JOIN 
    OrderDetails od ON o.o_orderkey = od.l_orderkey
LEFT JOIN 
    SupplierCost sc ON od.total_lineitem_value > sc.total_supplycost
LEFT JOIN 
    TopSuppliers ts ON ts.total_available > 100
WHERE 
    o.total_price_rank <= 10 AND 
    (o.o_orderstatus = 'F' OR o.o_orderstatus = 'P')
ORDER BY 
    o.o_orderdate DESC, 
    o.o_orderkey;
