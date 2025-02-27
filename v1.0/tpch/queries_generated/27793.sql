WITH SupplierDetails AS (
    SELECT 
        s_name, 
        s_address, 
        s_phone, 
        n_name AS nation_name, 
        r_name AS region_name,
        s_acctbal,
        CASE 
            WHEN s_acctbal < 1000 THEN 'Low Balance'
            WHEN s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Balance'
            ELSE 'High Balance'
        END AS balance_category
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p_name,
        p_mfgr,
        p_brand,
        p_type,
        p_size,
        p_container,
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rank
    FROM part
    WHERE p_retailprice > 100
),
OrderSummary AS (
    SELECT 
        o_custkey,
        COUNT(DISTINCT o_orderkey) AS total_orders,
        SUM(o_totalprice) AS total_spent,
        AVG(o_totalprice) AS avg_order_value
    FROM orders
    GROUP BY o_custkey
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    sd.balance_category,
    pd.p_name,
    pd.p_brand,
    od.total_orders,
    od.total_spent,
    od.avg_order_value
FROM SupplierDetails sd
JOIN PartDetails pd ON sd.s_name LIKE CONCAT('%', pd.p_brand, '%')
JOIN OrderSummary od ON sd.s_suppkey = od.o_custkey
WHERE sd.balance_category = 'High Balance'
ORDER BY od.total_spent DESC, pd.p_retailprice ASC;
