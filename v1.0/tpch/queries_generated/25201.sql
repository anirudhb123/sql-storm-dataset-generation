WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS mfgr_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        FORMAT(p.p_retailprice, 2) AS formatted_price,
        LEFT(p.p_comment, 20) AS short_comment
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        SUBSTRING(s.s_address, 1, 30) AS short_address,
        CONCAT(s.s_name, ' - ', r.r_name) AS supplier_region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value,
        CONCAT(c.c_name, ' has spent a total of ', FORMAT(SUM(o.o_totalprice), 2), ' across ', COUNT(o.o_orderkey), ' orders.') AS customer_summary
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalBenchmark AS (
    SELECT 
        pd.p_name,
        pd.mfgr_brand,
        pd.formatted_price,
        sd.short_address,
        co.customer_summary
    FROM 
        PartDetails pd
    JOIN 
        SupplierDetails sd ON pd.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 100 LIMIT 1)
    JOIN 
        CustomerOrders co ON co.total_spent > 1000
)
SELECT 
    *
FROM 
    FinalBenchmark
WHERE 
    LENGTH(co.customer_summary) > 50
ORDER BY 
    pd.formatted_price DESC;
