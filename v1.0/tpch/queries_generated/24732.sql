WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
), HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        CASE 
            WHEN p.p_retailprice IS NULL OR p.p_retailprice <= 0 THEN 'No Price'
            ELSE 'Priced'
        END AS price_status
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
), NationRegion AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    n.nation_name,
    nr.region_name,
    COALESCE(SUM(c.total_spent), 0) AS total_customer_spent,
    sr.supplier_count,
    COALESCE(MAX(hp.p_retailprice), 0) AS max_part_price,
    STRING_AGG(DISTINCT hp.price_status, ', ') AS price_status_summary
FROM NationRegion nr
LEFT JOIN HighValueParts hp ON nr.supplier_count > 0
LEFT JOIN CustomerPurchases c ON c.c_custkey IN (SELECT c_custkey FROM customer) 
JOIN nation n ON n.n_name = nr.nation_name
LEFT JOIN RankedSuppliers sr ON sr.rn = 1
GROUP BY n.nation_name, nr.region_name, sr.supplier_count
HAVING SUM(c.total_spent) IS NULL OR SUM(c.total_spent) > 1000
ORDER BY total_customer_spent DESC, nr.region_name ASC, n.nation_name DESC;
