WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
CustomerOrderStatus AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderstatus,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderstatus
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        AVG(s.ps_supplycost) AS avg_supply_cost
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        SupplierPartInfo s ON l.l_partkey = s.p_partkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.o_orderkey,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    r.o_orderdate,
    r.o_orderstatus,
    r.total_orders,
    o.total_value,
    o.avg_supply_cost,
    CASE 
        WHEN r.rank_status <= 5 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_category
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerOrderStatus c ON r.o_orderkey = c.o_orderkey
JOIN 
    OrderLineItems o ON r.o_orderkey = o.o_orderkey
WHERE 
    o.total_value > 1000
ORDER BY 
    r.o_orderdate DESC, customer_name;
