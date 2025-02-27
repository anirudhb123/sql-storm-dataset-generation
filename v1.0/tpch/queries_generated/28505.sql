WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type, ', Size: ', p.p_size, ', Retail Price: $', FORMAT(p.p_retailprice, 2), ', Comment: ', p.p_comment) AS p_full_details
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        r.r_name AS region_name,
        CONCAT('Supplier Name: ', s.s_name, ', Address: ', s.s_address, ', Region: ', r.r_name, ', Phone: ', s.s_phone, ', Account Balance: $', FORMAT(s.s_acctbal, 2), ', Comment: ', s.s_comment) AS s_full_details
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count,
        o.o_orderdate,
        CONCAT('Order Key: ', o.o_orderkey, ', Status: ', o.o_orderstatus, ', Total Revenue: $', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2), ', Item Count: ', COUNT(l.l_orderkey), ', Order Date: ', o.o_orderdate) AS o_full_summary
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
)
SELECT 
    pd.p_full_details,
    sd.s_full_details,
    os.o_full_summary
FROM 
    PartDetails pd
JOIN 
    SupplierDetails sd ON pd.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(pss.ps_supplycost) FROM partsupp pss WHERE pss.ps_partkey = pd.p_partkey) LIMIT 1)
JOIN 
    OrderSummary os ON os.item_count > 5
ORDER BY 
    os.total_revenue DESC
LIMIT 50;
