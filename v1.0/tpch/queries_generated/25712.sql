WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT(p.p_name, ' - ', p.p_type) AS FullDescription
    FROM 
        part p
    WHERE 
        p.p_retailprice > 0
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        LEAST(s.s_acctbal, 10000) AS LimitedAccountBalance
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        o.o_shippriority,
        o.o_comment,
        CASE 
            WHEN o.o_totalprice > 5000 THEN 'High Value Order'
            WHEN o.o_totalprice BETWEEN 1000 AND 5000 THEN 'Medium Value Order'
            ELSE 'Low Value Order' 
        END AS OrderValueCategory
    FROM 
        orders o
)

SELECT 
    pd.p_partkey,
    pd.FullDescription,
    sd.s_name AS SupplierName,
    od.OrderValueCategory,
    COUNT(od.o_orderkey) AS OrderCount
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    OrderDetails od ON li.l_orderkey = od.o_orderkey
WHERE 
    pd.p_size = (SELECT MAX(p_size) FROM part)
GROUP BY 
    pd.p_partkey, pd.FullDescription, sd.s_name, od.OrderValueCategory
ORDER BY 
    OrderCount DESC, pd.p_retailprice DESC
LIMIT 10;
