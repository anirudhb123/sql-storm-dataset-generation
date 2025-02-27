WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        COUNT(ps.ps_partkey) AS part_count,
        STRING_AGG(DISTINCT SUBSTRING(p.p_name, 1, 10), ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, s.s_phone, s.s_acctbal, s.s_comment
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    sd.nation,
    sd.part_count,
    sd.part_names,
    os.total_revenue,
    os.o_orderdate,
    os.o_orderstatus
FROM 
    SupplierDetails sd
LEFT JOIN 
    OrderSummary os ON sd.s_suppkey = os.o_orderkey
ORDER BY 
    sd.s_suppkey, os.total_revenue DESC;