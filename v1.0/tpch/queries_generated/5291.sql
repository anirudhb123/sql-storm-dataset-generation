WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rank
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
        ro.o_orderpriority,
        ro.c_name,
        ro.c_acctbal
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        p.p_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerSummary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(c.c_acctbal) AS total_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.o_orderpriority,
    sd.s_name AS supplier_name,
    sd.s_acctbal AS supplier_acctbal,
    cs.nation_name,
    cs.total_customers,
    cs.total_acctbal
FROM 
    TopOrders to
JOIN 
    SupplierDetails sd ON sd.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_supplycost = (SELECT MAX(ps_supplycost) FROM partsupp))
JOIN 
    CustomerSummary cs ON cs.total_customers > 100
ORDER BY 
    to.o_orderdate DESC, to.o_orderkey;
