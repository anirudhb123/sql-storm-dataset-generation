WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierPartAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY ps.ps_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    WHERE l.l_shipdate > NOW() - INTERVAL '1 year'
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name,
    SUM(l.total_line_value) AS total_sales,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT p.p_partkey) AS sold_parts,
    COALESCE(SUM(s.total_available), 0) AS total_avail_qty
FROM FilteredLineItems l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN HighValueCustomers c ON o.o_custkey = c.c_custkey
LEFT JOIN SupplierPartAvailability s ON array_to_string(ARRAY(SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps.ps_partkey = l.l_orderkey)), ',') LIKE '%' || CAST(s.ps_partkey AS TEXT) || '%'
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN part p ON p.p_partkey = l.l_orderkey
WHERE l.total_line_value > 100
GROUP BY n.n_name
ORDER BY total_sales DESC
LIMIT 10;
