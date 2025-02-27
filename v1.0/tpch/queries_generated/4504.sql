WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2024-01-01'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
ProductInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
OrderLineDetails AS (
    SELECT 
        l.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(*) AS line_item_count
    FROM 
        lineitem l
    GROUP BY 
        l.o_orderkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    cs.total_orders,
    cs.avg_order_value,
    COALESCE(SUM(OLD.total_line_value), 0) AS total_order_value,
    COALESCE(SUM(pi.total_avail_qty), 0) AS total_available_quantity,
    COALESCE(SUM(pi.avg_supply_cost), 0) AS average_supply_cost
FROM 
    CustomerSummary cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    OrderLineDetails OLD ON OLD.o_orderkey IN (SELECT o.o_orderkey FROM RankedOrders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    ProductInfo pi ON l.l_partkey = pi.p_partkey
WHERE 
    c.c_acctbal IS NOT NULL
GROUP BY 
    c.c_name, c.c_acctbal, cs.total_orders, cs.avg_order_value
ORDER BY 
    c.c_acctbal DESC
LIMIT 10;
