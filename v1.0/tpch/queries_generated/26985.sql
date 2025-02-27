WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        r.r_name AS region,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        REPLACE(UPPER(s.s_comment), 'SUPPLIER', 'SUPPLIER_REPLACED') AS modified_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name AS customer_name,
        c.c_mktsegment,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_mktsegment, o.o_orderdate
)
SELECT 
    sd.s_name AS supplier_name,
    pd.p_name AS part_name,
    od.customer_name,
    od.total_revenue,
    sd.modified_comment
FROM 
    SupplierDetails sd
JOIN 
    PartDetails pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = pd.p_partkey)
WHERE 
    sd.comment_length > 50
ORDER BY 
    sd.nation, od.total_revenue DESC;
