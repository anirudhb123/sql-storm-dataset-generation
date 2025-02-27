WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierAggregates AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        pa.total_supplycost,
        pa.supplier_count
    FROM 
        part p
    LEFT JOIN 
        SupplierAggregates pa ON p.p_partkey = pa.ps_partkey
    WHERE 
        pa.total_supplycost IS NOT NULL
        AND pa.total_supplycost > 10000
),
CustomerOrderStats AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    h.p_name,
    h.total_supplycost,
    co.order_count,
    co.avg_order_value,
    COALESCE(r.order_rank, 'No Orders') AS order_rank_status
FROM 
    HighValueParts h
LEFT JOIN 
    CustomerOrderStats co ON h.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost IN (SELECT MAX(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = h.p_partkey))
LEFT JOIN 
    RankedOrders r ON r.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year' AND o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_name = co.c_name))
WHERE 
    h.supplier_count > 5
ORDER BY 
    h.total_supplycost DESC, 
    co.avg_order_value ASC;
