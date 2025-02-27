WITH PartSupplierInfo AS (
    SELECT 
        p.p_name,
        s.s_name,
        SUBSTRING(s.s_address, 1, 20) AS short_address,
        CONCAT(LEFT(s.s_comment, 10), '...') AS short_comment,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerRegionSummary AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        STRING_AGG(CONCAT(s.s_name, ': ', l.l_quantity), '; ') AS supplier_info
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
FinalBenchmark AS (
    SELECT 
        psi.p_name,
        psi.s_name,
        psi.short_address,
        psi.short_comment,
        cr.nation_name,
        cr.region_name,
        od.total_revenue,
        od.supplier_info
    FROM 
        PartSupplierInfo psi
    JOIN 
        CustomerRegionSummary cr ON cr.customer_count > 1
    JOIN 
        OrderDetails od ON psi.s_name = od.supplier_info
)
SELECT 
    p_name,
    s_name,
    short_address,
    short_comment,
    nation_name,
    region_name,
    total_revenue
FROM 
    FinalBenchmark
ORDER BY 
    total_revenue DESC
LIMIT 10;
