WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Ordered'
            ELSE 'Not Ordered'
        END AS order_status_desc
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATEADD(month, -6, GETDATE()) AND GETDATE()
), 
SuppliersWithIncreasedCost AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost) > (
            SELECT AVG(ps2.ps_supplycost) 
            FROM partsupp ps2 
            WHERE ps2.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
        )
), 
CustomerStatus AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) >= 1 AND 
        DATEDIFF(day, MAX(o.o_orderdate), GETDATE()) <= 30
)
SELECT 
    n.n_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
    r.r_name,
    COALESCE(cs.order_count, 0) AS recent_customers,
    (SELECT COUNT(DISTINCT ps.ps_suppkey) 
     FROM SuppliersWithIncreasedCost) AS unusual_supplier_count
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerStatus cs ON c.c_custkey = cs.c_custkey
WHERE 
    l.l_shipdate >= DATEADD(year, -1, GETDATE()) 
    AND l.l_tax IS NOT NULL 
    AND l.l_discount BETWEEN 0 AND 0.1 
GROUP BY 
    n.n_name, r.r_name, cs.order_count
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY 
    total_sales DESC 
FETCH FIRST 10 ROWS ONLY;
