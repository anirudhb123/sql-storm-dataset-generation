WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate > (SELECT DATEADD(MONTH, -1, GETDATE()))
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 0
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS order_count,
        STRING_AGG(DISTINCT o.o_orderstatus, ', ') AS order_statuses
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY 
        c.c_custkey
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(o.o_orderdate, 'No Orders') AS last_order_date,
    COALESCE(s.total_available, 0) AS available_part_count,
    cs.avg_order_value,
    cs.order_count,
    CASE 
        WHEN cs.order_count > 5 THEN 'Frequent'
        WHEN cs.order_count BETWEEN 1 AND 5 THEN 'Infrequent'
        ELSE 'No Orders'
    END AS customer_status,
    CONCAT('Customer Comment: ', COALESCE(cs.order_statuses, 'None')) AS statuses
FROM 
    RankedOrders o
FULL OUTER JOIN 
    CustomerStats cs ON o.o_custkey = cs.c_custkey
LEFT JOIN 
    SupplierAvailability s ON s.ps_partkey = (
        SELECT TOP 1 ps.ps_partkey
        FROM partsupp ps
        WHERE ps.ps_availqty = (SELECT MAX(ps_inner.ps_availqty) FROM partsupp ps_inner)
        ORDER BY NEWID()
    )
WHERE 
    (o.o_orderkey IS NULL OR o.o_totalprice IS NOT NULL)
    AND (cs.avg_order_value IS NOT NULL OR s.total_available IS NOT NULL)
ORDER BY 
    customer_name ASC NULLS LAST;
