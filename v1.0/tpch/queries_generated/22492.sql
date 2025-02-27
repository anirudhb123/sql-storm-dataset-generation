WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
), 
TotalCustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
HighSpendCustomers AS (
    SELECT 
        c.c_custkey,
        tc.total_spent,
        tc.order_count 
    FROM TotalCustomerOrders tc
    JOIN customer c ON c.c_custkey = tc.c_custkey
    WHERE tc.total_spent > (SELECT AVG(total_spent) FROM TotalCustomerOrders)
), 
SupplierRating AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey, 
        ps.ps_availqty,
        SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey) AS total_supply_cost,
        (CASE 
            WHEN SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey) = 0 THEN 'No Supply'
            ELSE 'Available'
         END) AS supply_status
    FROM partsupp ps
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    (SELECT MAX(ps_availqty) FROM partsupp WHERE ps_partkey = p.p_partkey) AS max_avail_qty,
    COUNT(DISTINCT lc.c_custkey) FILTER (WHERE lc.order_count IS NOT NULL) AS distinct_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RankedSuppliers RS ON l.l_suppkey = RS.s_suppkey AND RS.rnk = 1
JOIN HighSpendCustomers lc ON lc.c_custkey = (SELECT c.c_custkey 
                                                FROM customer c 
                                                JOIN orders o ON c.c_custkey = o.o_custkey 
                                                WHERE o.o_orderkey = l.l_orderkey 
                                                LIMIT 1)
JOIN SupplierRating sr ON sr.ps_partkey = p.p_partkey
WHERE p.p_retailprice IS NOT NULL
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    RS.s_name
HAVING 
    total_revenue > (SELECT AVG(total_revenue) FROM (SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue 
                                                      FROM lineitem 
                                                      GROUP BY l_orderkey) AS revenue_per_order)
ORDER BY total_revenue DESC;
