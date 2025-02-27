WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders o
    JOIN 
        nation n ON o.c_nationkey = n.n_nationkey
    WHERE 
        o.total_price_rank <= 5
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_retailprice
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name,
    sp.p_name,
    sp.p_brand,
    sp.p_retailprice,
    sp.total_quantity_sold
FROM 
    TopOrders to
JOIN 
    SupplierParts sp ON to.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = sp.ps_partkey)
ORDER BY 
    to.o_orderdate DESC, 
    to.o_totalprice DESC, 
    sp.total_quantity_sold DESC;
