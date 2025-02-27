WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2022-01-01'
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
        ro.rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name,
    sd.s_name,
    sd.s_acctbal,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
JOIN 
    SupplierDetails sd ON l.l_partkey = sd.ps_partkey
GROUP BY 
    to.o_orderkey, to.o_orderdate, to.o_totalprice, to.c_name, sd.s_name, sd.s_acctbal
ORDER BY 
    total_value DESC;
