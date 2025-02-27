WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(COALESCE(ss.total_available, 0)) AS total_avail_qty,
    SUM(COALESCE(hvo.total_value, 0)) AS total_high_value_order
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    SupplierStats ss ON ss.s_nationkey = n.n_nationkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        JOIN supplier s ON l.l_suppkey = s.s_suppkey 
        WHERE s.s_nationkey = n.n_nationkey
    )
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
ORDER BY 
    num_customers DESC, total_high_value_order DESC;
