WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
        CASE 
            WHEN o.o_orderpriority = 'HIGH' THEN 'Priority High'
            WHEN o.o_orderpriority = 'NORMAL' THEN 'Priority Normal'
            ELSE 'Priority Low'
        END AS order_priority,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS net_spent
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_quantity > (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_orderkey = o.o_orderkey)
    AND 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(MAX(l.l_extendedprice * (1 - l.l_discount)), 0) AS max_price_per_part
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.order_priority,
    ss.part_count,
    ss.total_supply_value,
    pd.max_price_per_part,
    CASE 
        WHEN ro.net_spent > 1000 THEN 'High Spender'
        ELSE 'Low Spender'
    END AS customer_category
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierStats ss ON ss.part_count > 0
LEFT JOIN 
    PartDetails pd ON pd.max_price_per_part > 0
WHERE 
    ro.rn = 1
ORDER BY 
    ro.o_orderdate DESC, 
    ss.total_supply_value DESC
LIMIT 100;
