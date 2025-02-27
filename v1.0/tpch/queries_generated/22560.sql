WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderkey DESC) as rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) as total_value,
        COUNT(*) as item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipmode IN ('AIR', 'RAIL') 
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
SupplierPartAvailability AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_brand
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    WHERE 
        ps.ps_availqty >= (
            SELECT 
                AVG(ps2.ps_availqty) 
            FROM 
                partsupp ps2 
            WHERE 
                ps2.ps_supplycost < 50.00
        )
    AND 
        p.p_comment LIKE '%special%'
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(SUM(hv.total_value), 0) AS total_high_value,
    SUM(CASE WHEN so.rn IS NOT NULL THEN 1 ELSE 0 END) AS special_order_count,
    COUNT(DISTINCT spa.ps_partkey) AS available_parts
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    HighValueLineItems hv ON hv.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders so WHERE so.o_orderstatus = 'F')
LEFT JOIN 
    SupplierPartAvailability spa ON spa.ps_partkey IN (
        SELECT ps.ps_partkey FROM partsupp ps 
        WHERE ps.ps_availqty > 0 
        AND ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    )
WHERE 
    n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > (SELECT COUNT(*) FROM customer) / 10
ORDER BY 
    total_high_value DESC, customer_count DESC;
