WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE 
        l.l_shipdate <= DATEADD(MONTH, -1, GETDATE())
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_quantity) AS total_sold,
        AVG(l.l_extendedprice) AS average_price,
        MAX(l.l_discount) AS max_discount
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
    HAVING 
        SUM(l.l_quantity) IS NOT NULL AND SUM(l.l_quantity) > 0
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(CASE WHEN ps.total_avail_qty IS NULL THEN 0 ELSE ps.total_avail_qty END) AS total_available_qty,
    MAX(t.total_revenue) AS highest_supplier_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    RankedOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN 
    AvailableParts ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size BETWEEN 1 AND 10)
LEFT JOIN 
    TopSuppliers t ON t.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ps.ps_partkey)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 
    AND MAX(t.total_revenue) IS NOT NULL 
ORDER BY 
    r.r_name ASC, 
    total_customers DESC;
