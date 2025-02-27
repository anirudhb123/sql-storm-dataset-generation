WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT(p.p_name, ' - ', p.p_mfgr) AS full_description,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_comment,
        LENGTH(s.s_comment) AS supplier_comment_length
    FROM 
        supplier s
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_mktsegment,
        LENGTH(c.c_comment) AS customer_comment_length
    FROM 
        customer c
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_comment,
        LENGTH(o.o_comment) AS order_comment_length
    FROM 
        orders o
),
FinalBenchmark AS (
    SELECT 
        pd.full_description,
        sd.s_name AS supplier_name,
        cd.c_name AS customer_name,
        od.o_orderdate,
        od.o_totalprice,
        CONCAT(pd.full_description, ' | ', sd.s_name, ' | ', cd.c_name) AS benchmark_string,
        (pd.comment_length + sd.supplier_comment_length + cd.customer_comment_length + od.order_comment_length) AS total_comment_length
    FROM 
        PartDetails pd
    JOIN 
        partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN 
        supplier sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN 
        orders od ON li.l_orderkey = od.o_orderkey
    JOIN 
        customer cd ON od.o_custkey = cd.c_custkey
    WHERE 
        pd.p_retailprice > 50.00
    ORDER BY 
        total_comment_length DESC
)
SELECT * FROM FinalBenchmark LIMIT 100;
