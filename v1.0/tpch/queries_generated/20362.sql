WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
ActiveOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderpriority, 
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
        AND l.l_returnflag IS NULL 
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value_total
    FROM 
        lineitem l
    WHERE 
        l.l_discount BETWEEN 0.05 AND 0.15
    GROUP BY 
        l.l_orderkey
),
AggregatedData AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_orders_price,
        AVG(l.line_count) AS avg_line_items
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    INNER JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        ActiveOrders o ON c.c_custkey = o.o_orderkey
    LEFT JOIN 
        HighValueLineItems l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        r.r_name
)
SELECT 
    ad.r_name,
    ad.customer_count,
    COALESCE(ad.total_orders_price, 0) AS total_orders_price,
    COALESCE(ad.avg_line_items, 0) AS avg_line_items,
    CASE 
        WHEN ad.customer_count = 0 THEN 'No Customers'
        ELSE CAST(ad.total_orders_price / NULLIF(ad.customer_count, 0) AS DECIMAL(12,2))
    END AS avg_order_value
FROM 
    AggregatedData ad
JOIN 
    RankedSuppliers rs ON ad.customer_count > 5 AND rs.rn < 5
ORDER BY 
    ad.r_name, avg_order_value DESC
LIMIT 10;
