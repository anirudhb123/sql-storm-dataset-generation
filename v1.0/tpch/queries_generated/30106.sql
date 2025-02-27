WITH RECURSIVE OrderDates AS (
    SELECT 
        o_orderkey,
        o_orderdate
    FROM 
        orders
    WHERE 
        o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT 
        o.orderkey,
        DATE_ADD(o.o_orderdate, INTERVAL 1 DAY)
    FROM 
        orders o
    INNER JOIN 
        OrderDates od ON o.o_orderkey = od.o_orderkey
    WHERE 
        od.o_orderdate < CURRENT_DATE
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderLines AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS line_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    ol.total_price,
    ol.line_count,
    ss.total_available,
    ss.total_cost,
    (CASE 
        WHEN ss.total_available IS NULL THEN 'N/A'
        ELSE FORMAT(ss.total_available, 2)
    END) AS formatted_total_available,
    (CASE 
        WHEN ol.total_price IS NULL THEN 'No Price'
        ELSE FORMAT(ol.total_price, 2)
    END) AS formatted_total_price,
    CONCAT('Order Date: ', DATE_FORMAT(od.o_orderdate, '%Y-%m-%d')) AS order_info
FROM 
    OrderDates od
LEFT JOIN 
    OrderLines ol ON od.o_orderkey = ol.l_orderkey
LEFT JOIN 
    SupplierSummary ss ON ol.line_count > 2
WHERE 
    (od.o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE)
    AND (ol.total_price > 1000 OR ss.total_cost IS NOT NULL)
ORDER BY 
    od.o_orderdate DESC, 
    ol.total_price DESC;
