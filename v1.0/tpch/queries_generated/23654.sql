WITH RankedPart AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
), 
SupplierCustomer AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        c.c_custkey, 
        c.c_name,
        CASE
            WHEN c.c_acctbal IS NULL THEN 'Unknown'
            WHEN c.c_acctbal < 1000 THEN 'Low'
            WHEN c.c_acctbal >= 1000 AND c.c_acctbal < 5000 THEN 'Medium'
            ELSE 'High'
        END AS balance_category
    FROM supplier s
    JOIN customer c ON s.s_nationkey = c.c_nationkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name, 
    p.p_name,
    sc.s_name, 
    oc.total_order_value,
    AVG(COALESCE(oc.line_item_count, 0)) OVER (PARTITION BY r.r_name) AS avg_line_items,
    CASE 
        WHEN p.p_retailprice IS NOT NULL THEN 'Price Available' 
        ELSE 'Price Missing' 
    END AS price_status
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierCustomer sc ON s.s_suppkey = sc.s_suppkey
JOIN RankedPart p ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost ASC LIMIT 1)
LEFT JOIN OrderDetails oc ON oc.o_orderkey = (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderdate = (
        SELECT MAX(o2.o_orderdate) FROM orders o2 WHERE o2.o_orderkey = o.o_orderkey
    )
)
WHERE r.r_name LIKE 'A%'
AND p.rank <= 3
ORDER BY r.r_name, p.p_retailprice DESC, sc.balance_category;
