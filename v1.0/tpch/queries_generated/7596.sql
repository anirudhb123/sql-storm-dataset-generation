WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
HighValueOrders AS (
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
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, s.s_name, p.p_name, p.p_brand
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_extended_price,
        SUM(l.l_discount) AS total_discount,
        SUM(l.l_tax) AS total_tax
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    h.c_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    p.p_brand AS part_brand,
    ls.total_quantity,
    ls.total_extended_price,
    ls.total_discount,
    ls.total_tax
FROM 
    HighValueOrders h
JOIN 
    LineItemSummary ls ON h.o_orderkey = ls.l_orderkey
JOIN 
    SupplierDetails s ON s.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = h.o_orderkey)
ORDER BY 
    h.o_totalprice DESC, h.o_orderdate ASC;
