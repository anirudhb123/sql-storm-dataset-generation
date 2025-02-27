WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'P')
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
), 
TotalRevenue AS (
    SELECT 
        c.cust_key,
        SUM(co.total_revenue) AS grand_total
    FROM CustomerOrders co
    JOIN (SELECT DISTINCT c_custkey AS cust_key FROM customer) c ON co.c_custkey = c.cust_key
    GROUP BY c.cust_key
)

SELECT 
    r.s_suppkey,
    r.s_name,
    r.s_acctbal,
    t.grand_total
FROM RankedSuppliers r
FULL OUTER JOIN TotalRevenue t ON r.rn = 1
WHERE r.s_acctbal < COALESCE(t.grand_total, 0) * 0.1
ORDER BY r.s_acctbal DESC NULLS LAST;
