WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 10 
        AND p.p_retailprice IS NOT NULL
),
HighValueSuppliers AS (
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
        SUM(ps.ps_supplycost) > 10000
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SuspiciousOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        CASE 
            WHEN COUNT(*) > 5 THEN 'EXCEEDS_LIMIT' 
            ELSE 'WITHIN_LIMIT' 
        END AS order_status_class
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
    HAVING 
        COUNT(*) > 5
),
FinalResults AS (
    SELECT 
        cp.c_name AS customer_name,
        ps.p_name AS part_name,
        p.rank_by_price,
        so.order_status_class,
        ch.total_orders,
        ch.total_spent,
        hv.total_supply_cost
    FROM 
        HighValueSuppliers hv
    JOIN 
        RankedParts p ON hv.total_supply_cost > 50000 AND p.rank_by_price < 5
    JOIN 
        CustomerOrderStats ch ON hv.s_suppkey = ch.c_custkey
    JOIN 
        SuspiciousOrders so ON ch.total_orders > 3 AND so.o_orderkey = ch.c_custkey
    CROSS JOIN 
        customer cp
    WHERE 
        EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = cp.c_nationkey AND n.n_name IS NOT NULL)
)

SELECT 
    fr.customer_name,
    fr.part_name,
    fr.rank_by_price,
    fr.order_status_class,
    fr.total_orders,
    fr.total_spent,
    COALESCE(fr.total_supply_cost, 0) AS total_supply_cost
FROM 
    FinalResults fr
ORDER BY 
    fr.total_spent DESC, 
    fr.rank_by_price ASC 
LIMIT 100 OFFSET 50;
