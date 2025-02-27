WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
        COUNT(DISTINCT ps.ps_suppkey) OVER (PARTITION BY p.p_partkey) AS suppliers_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice IS NOT NULL
),
TopBrandParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        rp.suppliers_count
    FROM RankedParts rp
    WHERE rp.rank_price <= 3
),
OrdersWithHighValue AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Order Placed'
            WHEN o.o_orderstatus = 'F' AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) THEN 'Order Fulfilled - High Value'
            ELSE 'Other Status'
        END AS order_status_description
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_acctbal <= (SELECT MAX(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = 'SPECIAL')
),
FinalResult AS (
    SELECT 
        tbp.p_partkey,
        tbp.p_name,
        tbp.p_brand,
        ohv.o_orderkey,
        ohv.o_totalprice,
        ohv.c_name,
        ohv.order_status_description
    FROM TopBrandParts tbp
    LEFT JOIN OrdersWithHighValue ohv ON tbp.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ohv.o_orderkey LIMIT 1)
    WHERE tbp.suppliers_count >= (SELECT COUNT(DISTINCT s.s_suppkey) FROM supplier s WHERE s.s_acctbal > 50.00)
)
SELECT 
    p.p_partkey,
    p.p_name,
    CASE 
        WHEN o.o_orderkey IS NULL THEN 'No Orders'
        ELSE 'Order Exists'
    END AS order_status,
    p.p_brand,
    p.p_retailprice,
    COALESCE(o.c_name, 'Unknown Customer') AS customer_name,
    o.order_status_description
FROM part p
LEFT JOIN FinalResult o ON p.p_partkey = o.p_partkey
WHERE p.p_size BETWEEN 5 AND 10
UNION ALL
SELECT 
    NULL AS p_partkey,
    'Subquery Result' AS p_name,
    'N/A' AS p_brand,
    AVG(p.p_retailprice) AS p_retailprice,
    'Aggregate Result' AS customer_name,
    'Aggregated Data' AS order_status_description
FROM part p
WHERE p.p_retailprice IS NOT NULL
GROUP BY p.p_brand
HAVING AVG(p.p_retailprice) > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL);
