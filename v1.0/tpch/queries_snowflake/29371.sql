
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name,
        SUBSTRING(s.s_comment, 1, 30) AS short_comment,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        s.s_acctbal,
        s.short_comment,
        s.comment_length
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        SupplierDetails s ON ps.ps_suppkey = s.s_suppkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
)
SELECT 
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    SUM(od.l_quantity) AS total_quantity,
    SUM(od.l_extendedprice) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_account_balance,
    LISTAGG(DISTINCT s.short_comment, '; ') AS supplier_comments_summary,
    MAX(s.comment_length) AS max_supplier_comment_length
FROM 
    PartSupplierDetails pd
JOIN 
    OrderDetails od ON pd.ps_partkey = od.l_partkey
JOIN 
    SupplierDetails s ON pd.ps_suppkey = s.s_suppkey
WHERE 
    od.l_returnflag = 'N'
GROUP BY 
    pd.p_name, pd.p_brand, pd.p_type
ORDER BY 
    total_revenue DESC
LIMIT 10;
