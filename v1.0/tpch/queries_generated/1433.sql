WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    o.o_orderkey,
    o.o_totalprice,
    s.s_name,
    ps.ps_availqty,
    COALESCE(NULLIF(o.o_orderstatus, 'F'), 'Unknown') AS adjusted_status,
    ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS shipment_rank,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    RankedOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueSuppliers s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerOrderCounts c ON o.o_custkey = c.c_custkey
WHERE 
    (o.o_orderstatus IN ('O', 'F') AND l.l_shipmode = 'AIR')
    OR (o.o_totalprice > 1000 AND s.total_cost IS NOT NULL)
ORDER BY 
    o.o_orderdate DESC, s.total_cost DESC;
