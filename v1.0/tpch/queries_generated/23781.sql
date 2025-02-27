WITH RECURSIVE RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_availqty) AS total_available,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o1.o_totalprice) FROM orders o1) 
        OR EXISTS (SELECT 1 FROM customer c WHERE c.c_custkey = o.o_custkey AND c.c_mktsegment = 'BUILDING')
), NationSupplier AS (
    SELECT 
        n.n_name, 
        s.s_suppkey, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_name, s.s_suppkey
    HAVING 
        COUNT(o.o_orderkey) > 0
), CombinedResults AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        CASE 
            WHEN ns.order_count IS NOT NULL THEN ns.order_count
            ELSE 0
        END AS total_orders,
        rp.total_available
    FROM 
        RankedParts rp
    LEFT JOIN 
        NationSupplier ns ON rp.p_partkey = ns.s_suppkey
    WHERE 
        rp.rn <= 3
)
SELECT 
    cr.p_partkey, 
    cr.p_name, 
    cr.total_orders, 
    cr.total_available,
    CASE 
        WHEN cr.total_orders > 0 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS activity_status
FROM 
    CombinedResults cr
WHERE 
    cr.total_available > 100 
    OR cr.total_orders IS NULL
ORDER BY 
    cr.total_available DESC, 
    cr.activity_status DESC;
