WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        RANK() OVER (PARTITION BY o.o_shippriority ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_suppkey) as supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rn
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2 
            WHERE c2.c_acctbal IS NOT NULL
        )
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(sa.total_avail_qty, 0) AS available_quantity,
    ra.o_orderdate,
    ra.o_shippriority
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
JOIN 
    RankedOrders ra ON l.l_orderkey = ra.o_orderkey
JOIN 
    HighValueCustomers hvc ON l.l_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = l.l_partkey 
        ORDER BY ps.ps_supplycost 
        LIMIT 1
    )
WHERE 
    l.l_returnflag = 'N'
GROUP BY 
    p.p_name, ra.o_orderdate, ra.o_shippriority, sa.total_avail_qty
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC, ra.o_shippriority;
