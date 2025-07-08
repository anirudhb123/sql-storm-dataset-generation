WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        n.n_name AS nation_name, 
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_totalprice, 
        r.c_name
    FROM 
        RankedOrders r
    WHERE 
        r.price_rank <= 5
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_name,
        p.p_brand 
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    t.c_name AS customer_name, 
    t.o_orderkey, 
    t.o_totalprice, 
    s.s_name AS supplier_name, 
    s.s_acctbal AS supplier_acctbal, 
    s.p_name AS part_name, 
    s.p_brand AS part_brand
FROM 
    TopOrders t
JOIN 
    SupplierDetails s ON t.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = s.ps_partkey)
ORDER BY 
    t.o_totalprice DESC, 
    s.s_acctbal DESC;
