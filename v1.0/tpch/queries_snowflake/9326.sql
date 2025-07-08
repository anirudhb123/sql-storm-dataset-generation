WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_average
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerMetrics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer AS c
    LEFT JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    SUM(ss.total_available_quantity) AS total_quantity,
    AVG(os.total_price_average) AS avg_order_price,
    SUM(cm.total_orders) AS total_orders_per_customer
FROM 
    region AS r
JOIN 
    nation AS n ON r.r_regionkey = n.n_regionkey
JOIN 
    SupplierSummary AS ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type = 'MANUFACTURING'))
JOIN 
    OrderSummary AS os ON os.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN 
    CustomerMetrics AS cm ON cm.c_custkey = os.o_custkey
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_quantity DESC, avg_order_price ASC;
