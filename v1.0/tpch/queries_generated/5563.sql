WITH OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS total_lineitems
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        os.total_revenue,
        os.total_lineitems,
        spd.total_availqty,
        spd.avg_supplycost
    FROM 
        OrdersSummary os
    JOIN 
        nation n ON os.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierPartDetails spd ON spd.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
    WHERE 
        os.total_revenue > 10000
    ORDER BY 
        os.total_revenue DESC
)
SELECT 
    region_name,
    nation_name,
    SUM(total_revenue) AS total_revenue,
    SUM(total_lineitems) AS total_lineitems,
    SUM(total_availqty) AS total_availqty,
    AVG(avg_supplycost) AS avg_supplycost
FROM 
    FinalReport
GROUP BY 
    region_name, nation_name
ORDER BY 
    total_revenue DESC;
