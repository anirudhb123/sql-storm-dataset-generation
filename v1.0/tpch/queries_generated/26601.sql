WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' (', s.s_name, ')') AS part_supplier_concat
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
RegionNationDetails AS (
    SELECT 
        r.r_regionkey,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name, n.n_name
)
SELECT 
    rnd.region_name,
    rnd.nation_name,
    psd.part_supplier_concat,
    cod.c_name AS customer_name,
    cod.total_revenue,
    COALESCE(rnd.supplier_count, 0) AS total_suppliers
FROM 
    PartSupplierDetails psd
JOIN 
    CustomerOrderDetails cod ON TRUE
LEFT JOIN 
    RegionNationDetails rnd ON psd.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'NATION_NAME')))
WHERE 
    cod.total_revenue > 5000
ORDER BY 
    rnd.region_name, cod.total_revenue DESC;
