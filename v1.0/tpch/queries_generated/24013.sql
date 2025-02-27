WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        OR (o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < '2023-01-01'))
),
EligibleSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 100 
        AND (COUNT(DISTINCT ps.ps_partkey) FILTER (WHERE ps.ps_supplycost > 500) > 1)
),
NonNullParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        COALESCE(NULLIF(p.p_brand, ''), 'Unknown') AS normalized_brand,
        p.p_retailprice * (1 - 0.1 * (p.p_size / 10)) AS discounted_price
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
        AND p.p_size BETWEEN 1 AND 30
)
SELECT 
    no.p_partkey, 
    no.p_name, 
    es.total_supply_cost, 
    ro.o_orderkey, 
    ro.o_totalprice
FROM 
    NonNullParts no
LEFT JOIN 
    EligibleSuppliers es ON es.total_supply_cost < (no.discounted_price * 1.5)
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey = (SELECT MAX(o2.o_orderkey) 
                                          FROM RankedOrders ro2 
                                          WHERE ro2.o_orderkey >= ro.o_orderkey
                                          AND ro2.order_rank < 10)
WHERE 
    EXISTS (SELECT 1 
            FROM lineitem l 
            WHERE l.l_partkey = no.p_partkey 
            AND l.l_quantity < (SELECT AVG(l2.l_quantity) 
                                FROM lineitem l2 
                                WHERE l2.l_partkey = no.p_partkey))
ORDER BY 
    no.discounted_price DESC, 
    es.total_supply_cost, 
    ro.o_orderdate;
