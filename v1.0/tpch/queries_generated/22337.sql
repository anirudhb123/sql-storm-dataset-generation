WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Select suppliers with above-average account balance

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey AND sh.level < 5 -- Limit hierarchy depth

),
PartRanking AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as price_rank
    FROM part p
    WHERE p.p_size IS NOT NULL AND p.p_size < 100 -- Include only parts with a specified size and size < 100
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(l.l_tax) AS max_tax,
        MIN(l.l_discount) AS min_discount,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01' -- Filter for recent orders
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_revenue,
        od.max_tax,
        CASE 
            WHEN od.total_revenue > 1000 THEN 'High'
            WHEN od.total_revenue BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_category
    FROM OrderDetails od
    WHERE od.supplier_count > 5 -- Select orders with more than 5 different suppliers
)
SELECT 
    rh.r_name,
    COUNT(DISTINCT oh.o_orderkey) AS high_value_order_count,
    AVG(pr.price_rank) AS average_price_rank
FROM region rh
JOIN nation n ON rh.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT OUTER JOIN HighValueOrders oh ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                                      FROM partsupp ps 
                                                      WHERE ps.ps_partkey IN (SELECT pr.p_partkey FROM PartRanking pr WHERE pr.price_rank = 1)
                                                      LIMIT 1) -- Grab supplier from highest ranked part
LEFT JOIN PartRanking pr ON pr.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE rh.r_name IS NOT NULL
GROUP BY rh.r_name
HAVING COUNT(DISTINCT oh.o_orderkey) > 0 AND AVG(pr.price_rank) IS NOT NULL -- Only include regions with high-value orders and valid average rank
ORDER BY high_value_order_count DESC, r_name;
