WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE) 
        AND o.o_orderstatus IN ('O', 'F')
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name 
    FROM 
        SupplierDetails s
    WHERE 
        s.total_supply_cost > (
            SELECT AVG(total_supply_cost) 
            FROM SupplierDetails
        ) 
        ORDER BY s.total_supply_cost DESC
    LIMIT 5
)
SELECT 
    p.p_name, 
    COALESCE(MAX(l.l_discount), 0) AS max_discount, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount, 
    r.r_name AS region
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    EXISTS (
        SELECT 1 
        FROM TopSuppliers ts 
        WHERE ts.s_suppkey = l.l_suppkey
    )
    AND (p.p_size BETWEEN 1 AND 10 OR p.p_mfgr LIKE 'Manufacturer%')
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 
    AND MAX(l.l_discount) IS NOT NULL
ORDER BY 
    avg_price_after_discount DESC, customer_count ASC;
