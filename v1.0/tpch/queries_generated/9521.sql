WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.total_price, 
        o.o_orderstatus
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.order_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
FinalResults AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        s.s_name,
        sd.total_supplier_cost,
        o.total_price,
        (sd.total_supplier_cost / o.total_price) AS cost_ratio
    FROM 
        TopOrders o
    JOIN 
        SupplierDetails sd ON o.o_orderkey = sd.ps_partkey
    JOIN 
        supplier s ON sd.ps_suppkey = s.s_suppkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_orderstatus,
    s.s_name,
    total_supplier_cost,
    total_price,
    cost_ratio
FROM 
    FinalResults o
JOIN 
    supplier s ON o.s_suppkey = s.s_suppkey
ORDER BY 
    cost_ratio DESC, total_price DESC;
