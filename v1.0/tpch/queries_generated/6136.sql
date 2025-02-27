WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        lm.l_orderkey,
        lm.l_quantity,
        lm.l_discount
    FROM 
        part p
    JOIN 
        lineitem lm ON lm.l_partkey = p.p_partkey
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
FinalReport AS (
    SELECT 
        to.o_orderkey,
        to.o_orderdate,
        to.o_totalprice,
        pd.p_name,
        pd.p_brand,
        pd.p_retailprice,
        pd.l_quantity,
        pd.l_discount,
        si.s_name,
        si.s_acctbal
    FROM 
        TopOrders to
    JOIN 
        ProductDetails pd ON pd.l_orderkey = to.o_orderkey
    JOIN 
        SupplierInfo si ON si.ps_partkey = pd.p_partkey
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    f.p_name,
    f.p_brand,
    f.p_retailprice,
    f.l_quantity,
    f.l_discount,
    f.s_name,
    f.s_acctbal
FROM 
    FinalReport f
ORDER BY 
    f.o_orderdate DESC, 
    f.o_totalprice DESC;
