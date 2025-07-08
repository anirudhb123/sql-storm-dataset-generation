WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
total_spent AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1996-01-01'
    GROUP BY l.l_suppkey
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CASE 
            WHEN o.o_totalprice > 1000 THEN 'High'
            WHEN o.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS order_value
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
nations_info AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    p.p_name,
    ps.ps_availqty,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    ns.n_name AS nation_name,
    th.total AS total_spent,
    (SELECT SUM(l_extendedprice * (1 - l_discount)) 
     FROM lineitem 
     WHERE l_partkey = p.p_partkey) AS total_part_revenue,
    CASE 
        WHEN th.total > 50000 THEN 'Very High'
        WHEN th.total BETWEEN 20000 AND 50000 THEN 'High'
        ELSE 'Normal'
    END AS spending_category
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN ranked_suppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rnk <= 3
LEFT JOIN total_spent th ON th.l_suppkey = ps.ps_suppkey
CROSS JOIN nations_info ns
WHERE p.p_retailprice BETWEEN 10 AND 100 
  AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size IS NOT NULL)
  AND EXISTS (SELECT 1 
              FROM orders o 
              WHERE o.o_custkey = (SELECT c.c_custkey 
                                   FROM customer c 
                                   WHERE c.c_nationkey = ns.n_nationkey 
                                   ORDER BY c.c_acctbal DESC 
                                   LIMIT 1) 
              AND o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year')
ORDER BY total_spent DESC, supplier_name;