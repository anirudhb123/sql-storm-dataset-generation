WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_orderdate,
        o_totalprice,
        o_orderstatus,
        RANK() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) as order_rank
    FROM 
        orders
    WHERE 
        o_orderdate >= DATE '2022-01-01' AND o_orderdate < DATE '2023-01-01'
),
SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS supplier_count,
        SUM(s_acctbal) AS total_balance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
ProductDetails AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_type,
        SUM(ps_availqty) AS total_available
    FROM 
        part
    JOIN 
        partsupp ON p_partkey = ps_partkey
    WHERE 
        p_size >= 10 AND p_retailprice > 200
    GROUP BY 
        p_partkey, p_name, p_brand, p_type
)
SELECT 
    o.orderkey,
    o.orderdate,
    o.totalprice,
    ps.supplier_count,
    ps.total_balance,
    pd.total_available,
    CASE 
        WHEN o.orderstatus = 'O' THEN 'Open'
        ELSE 'Closed' 
    END AS order_status,
    COALESCE(pd.p_name, 'N/A') AS product_name
FROM 
    RankedOrders o
LEFT JOIN 
    SupplierStats ps ON ps.s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
LEFT JOIN 
    ProductDetails pd ON pd.p_partkey = (SELECT l_partkey FROM lineitem WHERE l_orderkey = o.o_orderkey LIMIT 1)
WHERE 
    o.order_rank <= 5 
    AND (o.totalprice > 500 OR pd.total_available IS NOT NULL)
ORDER BY 
    o.orderdate DESC, o.totalprice DESC;
