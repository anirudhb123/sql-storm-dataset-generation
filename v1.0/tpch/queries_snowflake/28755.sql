WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_container,
        CONCAT(p.p_name, ' - ', p.p_mfgr, ' - ', p.p_type) AS full_description,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        CONCAT(s.s_name, ' (', n.n_name, ')') AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 500.00
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        SUBSTRING(c.c_comment, 1, 15) AS short_comment
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000.00
),
OrderCounts AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)
SELECT 
    pd.p_name,
    pd.full_description,
    sd.supplier_info,
    cd.c_name,
    cd.short_comment,
    oc.order_count,
    pd.comment_length
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerDetails cd ON cd.c_custkey = (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderkey = (
                SELECT 
                    l.l_orderkey 
                FROM 
                    lineitem l 
                WHERE 
                    l.l_partkey = pd.p_partkey 
                LIMIT 1
            )
    )
JOIN 
    OrderCounts oc ON cd.c_custkey = oc.o_custkey
ORDER BY 
    pd.comment_length DESC, 
    oc.order_count DESC;
