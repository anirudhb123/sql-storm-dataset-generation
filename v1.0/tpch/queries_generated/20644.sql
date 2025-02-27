WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        DATEDIFF(CURDATE(), o.o_orderdate) AS days_since_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR
        ) OR
        o.o_orderstatus IN ('O', 'F')
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS orders_count,
        CASE 
            WHEN AVG(o.o_totalprice) IS NOT NULL THEN 
                SUM(o.o_totalprice) / COUNT(o.o_orderkey) ELSE 0
        END AS calculated_avg_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_container, 
    COALESCE(RS.total_cost, 0) AS supplier_cost, 
    CS.avg_order_value, 
    COALESCE(CS.orders_count, 0) AS total_orders,
    CASE 
        WHEN CS.calculated_avg_price > 1000.00 THEN 'High Value'
        ELSE 'Standard Value'
    END AS customer_category,
    N.n_name AS nation_name,
    R.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    RankedSuppliers RS ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
LEFT JOIN 
    customer c ON c.c_custkey IN (SELECT o.o_custkey FROM RecentOrders o WHERE o.o_orderstatus = 'O')
JOIN 
    nation N ON c.c_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    (p.p_size BETWEEN 1 AND 10 OR p.p_container IS NULL)
    AND (CS.orders_count > (SELECT AVG(orders_count) FROM CustomerStats))
ORDER BY 
    supplier_cost DESC, 
    p.p_retailprice ASC, 
    days_since_order ASC;
