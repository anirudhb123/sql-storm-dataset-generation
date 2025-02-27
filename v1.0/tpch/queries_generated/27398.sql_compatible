
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
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        s.s_phone AS supplier_phone,
        s.s_comment AS supplier_comment,
        c.c_name AS customer_name,
        c.c_acctbal AS customer_acctbal,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_totalprice
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_retailprice > 50.00
    AND 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
AggregatedData AS (
    SELECT 
        p_mfgr,
        COUNT(DISTINCT p_partkey) AS total_parts,
        SUM(p_retailprice) AS total_retail_price,
        AVG(ps_availqty) AS avg_availability,
        STRING_AGG(DISTINCT supplier_name, '; ') AS suppliers_list,
        STRING_AGG(DISTINCT customer_name, '; ') AS customers_list,
        MAX(o_totalprice) AS max_order_value
    FROM 
        PartDetails
    GROUP BY 
        p_mfgr
)
SELECT 
    p_mfgr,
    total_parts,
    total_retail_price,
    avg_availability,
    suppliers_list,
    customers_list,
    max_order_value,
    CONCAT('Total parts: ', total_parts, ', Total Retail Price: ', total_retail_price, ', Avg Availability: ', avg_availability) AS summary
FROM 
    AggregatedData
ORDER BY 
    total_parts DESC;
