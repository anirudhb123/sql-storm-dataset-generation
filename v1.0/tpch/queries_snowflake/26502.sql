
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > 500 AND 
        p.p_name LIKE '%steel%'
),
CombinedData AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        SUM(l.l_extendedprice - l.l_discount) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        s.s_name,
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank <= 3
    WHERE 
        EXISTS (SELECT 1 FROM FilteredParts fp WHERE fp.p_partkey = ps.ps_partkey)
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, s.s_name, s.s_acctbal
)
SELECT 
    fp.p_name, 
    SUM(cd.total_revenue) AS total_supplied_revenue,
    SUM(cd.order_count) AS total_orders,
    MAX(cd.s_acctbal) AS max_supplier_balance,
    AVG(cd.s_acctbal) AS avg_supplier_balance,
    SUM(fp.comment_length) AS total_comment_length
FROM 
    CombinedData cd
JOIN 
    FilteredParts fp ON cd.ps_partkey = fp.p_partkey
GROUP BY 
    fp.p_name
ORDER BY 
    total_supplied_revenue DESC, avg_supplier_balance DESC;
