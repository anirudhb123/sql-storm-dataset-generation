WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
HighValueLines AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY l.l_orderkey
),
SupplierPartData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000.00
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(hv.total_revenue, 0) AS total_revenue,
    COALESCE(s.total_cost, 0) AS total_cost,
    f.c_name,
    f.c_acctbal
FROM RankedOrders r
LEFT JOIN HighValueLines hv ON r.o_orderkey = hv.l_orderkey
LEFT JOIN SupplierPartData s ON s.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey LIMIT 1)
JOIN FilteredCustomers f ON r.o_orderkey = f.c_custkey
WHERE r.rank <= 10
AND r.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY r.o_orderdate DESC;
