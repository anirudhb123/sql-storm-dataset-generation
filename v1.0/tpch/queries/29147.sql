
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
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS description
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        CONCAT('Supplier: ', s.s_name, ', Phone: ', s.s_phone, ', Nation: ', n.n_name) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        o.o_shippriority,
        o.o_comment,
        STRING_AGG(DISTINCT CONCAT('Order: ', o.o_orderkey, ', Status: ', o.o_orderstatus, ', Total Price: ', o.o_totalprice), '; ') AS order_info
    FROM orders o
    GROUP BY 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        o.o_clerk, 
        o.o_shippriority, 
        o.o_comment
)
SELECT 
    pd.description,
    sd.supplier_info,
    od.order_info
FROM PartDetails pd
JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN OrderDetails od ON pd.p_partkey = (
    SELECT l.l_partkey 
    FROM lineitem l 
    WHERE l.l_orderkey = od.o_orderkey 
    LIMIT 1
)
WHERE pd.p_size > 30
ORDER BY pd.p_retailprice DESC, sd.nation_name ASC;
