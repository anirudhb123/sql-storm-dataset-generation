WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_partkey,
        COUNT(l.l_orderkey) AS orders_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2022-01-01'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    ROUND(AVG(s.total_supply_cost), 2) AS avg_supply_cost,
    MAX(cs.total_spent) AS highest_customer_spent,
    SUM(l.orders_count) AS total_orders,
    SUM(l.total_revenue) AS total_revenue_generated,
    counting_status = CASE 
        WHEN COUNT(o.o_orderkey) > 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END
FROM part p
LEFT JOIN SupplierInfo s ON s.part_count > 0
LEFT JOIN CustomerStats cs ON cs.order_count > 0
LEFT JOIN LineItemStats l ON l.l_partkey = p.p_partkey
RIGHT JOIN RankedOrders ro ON o.o_orderkey = ro.o_orderkey
WHERE 
    p.p_retailprice > 20.00
GROUP BY 
    p.p_name, p.p_brand, p.p_container
HAVING 
    COUNT(s.s_suppkey) > 1
ORDER BY 
    avg_supply_cost DESC;
