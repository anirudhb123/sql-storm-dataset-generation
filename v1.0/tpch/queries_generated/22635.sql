WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'P')
), 
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(NULLIF(c.c_address, ''), 'Unknown') AS address_info
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2
            WHERE c2.c_nationkey = c.c_nationkey
        )
), 
SupplyStats AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 10
)

SELECT 
    r.r_name,
    p.p_name,
    p.p_retailprice,
    o.o_orderkey,
    co.c_name AS customer_name,
    coalesce(ranked.order_rank, -1) AS order_rank,
    s.total_available
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplyStats ss ON ss.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    RankedOrders ranked ON ranked.o_orderkey = l.l_orderkey
INNER JOIN 
    CustomerInfo co ON co.c_custkey = (SELECT o2.o_custkey FROM orders o2 WHERE o2.o_orderkey = l.l_orderkey LIMIT 1)
WHERE 
    EXISTS (
        SELECT 1 
        FROM lineitem l2 
        WHERE l2.l_orderkey = l.l_orderkey 
        AND l2.l_discount > 0.05
    )
AND 
    p.p_size BETWEEN 10 AND 20
ORDER BY 
    r.r_name, p.p_name;
