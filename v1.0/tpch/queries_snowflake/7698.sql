WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
), SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
), FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        su.supplier_count,
        su.total_avail_qty,
        su.avg_supply_cost,
        n.n_name AS supplier_nation_name
    FROM 
        RankedOrders ro
    JOIN 
        SupplierStats su ON su.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
    JOIN 
        nation n ON su.s_nationkey = n.n_nationkey
    WHERE 
        ro.rn <= 10
)
SELECT 
    *
FROM 
    FinalReport
ORDER BY 
    o_orderstatus, o_totalprice DESC;