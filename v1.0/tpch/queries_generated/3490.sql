WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank,
        c.c_name,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        ro.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank <= 5
),
SupplierDetails AS (
    SELECT 
        DISTINCT ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 50
),
OrdersWithPartDetails AS (
    SELECT 
        hvo.o_orderkey,
        hvo.o_orderdate,
        hvo.o_totalprice,
        hvo.nation_name,
        l.l_partkey,
        p.p_name,
        p.p_retailprice,
        s.s_name AS supplier_name
    FROM 
        HighValueOrders hvo
    JOIN 
        lineitem l ON hvo.o_orderkey = l.l_orderkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    LEFT JOIN 
        SupplierDetails s ON l.l_partkey = s.ps_partkey
)
SELECT 
    ov.o_orderkey,
    ov.o_orderdate,
    ov.o_totalprice,
    ov.nation_name,
    COUNT(DISTINCT ov.l_partkey) AS distinct_parts_count,
    AVG(p.p_retailprice) AS avg_part_price,
    SUM(COALESCE(s.s_acctbal, 0)) AS total_supplier_acctbal
FROM 
    OrdersWithPartDetails ov
LEFT JOIN 
    SupplierDetails s ON ov.l_partkey = s.ps_partkey
GROUP BY 
    ov.o_orderkey, ov.o_orderdate, ov.o_totalprice, ov.nation_name
HAVING 
    SUM(s.ps_supplycost) < 1000
ORDER BY 
    ov.o_totalprice DESC;
