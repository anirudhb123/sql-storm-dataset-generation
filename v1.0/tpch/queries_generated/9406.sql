WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        (SELECT AVG(ps_supplycost) 
         FROM partsupp ps2 
         WHERE ps2.ps_partkey = ps.ps_partkey) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        ps.ps_availqty > 100
),
FinalResult AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT cu.c_custkey) AS customer_count,
        SUM(ro.total_value) AS total_order_value
    FROM 
        RankedOrders ro
    JOIN 
        customer cu ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cu.c_custkey)
    JOIN 
        supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    fr.region_name,
    fr.customer_count,
    fr.total_order_value,
    sd.supplier_nation,
    sd.s_name,
    sd.avg_supplycost,
    ROW_NUMBER() OVER (PARTITION BY fr.region_name ORDER BY fr.total_order_value DESC) AS region_rank
FROM 
    FinalResult fr
JOIN 
    SupplierDetails sd ON fr.total_order_value > 10000
ORDER BY 
    fr.region_name, region_rank;
