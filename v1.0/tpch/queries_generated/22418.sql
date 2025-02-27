WITH SupplierRanked AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        COALESCE(
            (SELECT SUM(ps.ps_supplycost) 
             FROM partsupp ps 
             WHERE ps.ps_suppkey = s.s_suppkey), 
            0) AS total_supplycost
    FROM supplier s
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_brand,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown Price'
            WHEN p.p_retailprice > 1000 THEN 'High' 
            ELSE 'Low'
        END AS price_category
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 25
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM CustomerOrders co
    WHERE co.order_count > 5
)

SELECT
    pr.p_partkey,
    pr.p_brand,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    sr.s_name AS supplier_name,
    sr.rank AS supplier_rank,
    tc.c_name AS top_customer_name,
    tc.customer_rank AS top_customer_rank
FROM FilteredParts pr
JOIN lineitem l ON pr.p_partkey = l.l_partkey
LEFT JOIN SupplierRanked sr ON l.l_suppkey = sr.s_suppkey AND sr.rank = 1
JOIN TopCustomers tc ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey)
GROUP BY pr.p_partkey, pr.p_brand, sr.s_name, sr.rank, tc.c_name, tc.customer_rank
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC, total_orders DESC
LIMIT 10;
