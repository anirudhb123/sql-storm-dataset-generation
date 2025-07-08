WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
), 
SupplierCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS uniq_suppliers
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
OrderItemDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS item_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    sc.uniq_suppliers,
    cus.total_spent,
    ois.total_price,
    ois.item_count,
    ois.avg_quantity,
    CASE 
        WHEN rp.rn = 1 THEN 'Most Expensive in Brand'
        ELSE 'Standard'
    END AS price_rank_status,
    CASE 
        WHEN cus.total_spent IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS customer_order_status
FROM RankedParts rp
LEFT JOIN SupplierCounts sc ON rp.p_partkey = sc.ps_partkey
LEFT JOIN CustomerOrderSummary cus ON sc.uniq_suppliers > 1 AND cus.c_custkey = (SELECT c.c_custkey FROM customer c WHERE RANDOM() < 0.1 ORDER BY RANDOM() LIMIT 1)
LEFT JOIN OrderItemDetails ois ON ois.o_orderkey = (SELECT o.o_orderkey 
                                                     FROM orders o 
                                                     WHERE o.o_orderstatus = 'O' 
                                                     ORDER BY RANDOM() 
                                                     LIMIT 1)
WHERE 
    rp.p_retailprice IS NOT NULL 
    AND rp.p_name LIKE '%' || CAST(NULLIF((SELECT MIN(p2.p_size) FROM part p2 WHERE p2.p_size IS NOT NULL), 0) AS VARCHAR) || '%' 
    AND (sc.uniq_suppliers IS NULL OR sc.uniq_suppliers > 5 OR sc.uniq_suppliers = (SELECT MAX(uniq_suppliers) FROM SupplierCounts));
