WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CONCAT(p.p_name, ' // ', p.p_brand) AS part_info
    FROM 
        part p
    WHERE 
        p.p_retailprice < (SELECT AVG(p_retailprice) FROM part)
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        l.l_shipdate,
        l.l_returnflag,
        l.l_comment
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_shipdate, l.l_returnflag, l.l_comment
)
SELECT 
    sdf.supplier_info,
    pdf.part_info,
    lid.total_revenue,
    lid.l_shipdate
FROM 
    SupplierDetails sdf
JOIN 
    PartDetails pdf ON sdf.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pdf.p_partkey LIMIT 1)
JOIN 
    LineItemDetails lid ON lid.l_partkey = pdf.p_partkey
WHERE 
    lid.total_revenue > 50000
ORDER BY 
    lid.total_revenue DESC;