WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopRegions AS (
    SELECT 
        r.r_name,
        SUM(CASE WHEN p.p_retailprice > 100.00 THEN 1 ELSE 0 END) AS high_value_parts
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_name
)
SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    oh.total_revenue,
    sd.s_name,
    sd.total_cost,
    tr.r_name,
    tr.high_value_parts
FROM 
    OrderHierarchy oh
JOIN 
    SupplierDetails sd ON oh.o_orderkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey LIMIT 1)
LEFT JOIN 
    TopRegions tr ON sd.s_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE tr.r_name = s.s_name);
