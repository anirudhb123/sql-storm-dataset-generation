WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1995-01-01'
),
SupplierAggregates AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    sa.total_avail_qty,
    sa.avg_supply_cost,
    CASE 
        WHEN ra.order_rank IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    part p
LEFT JOIN 
    SupplierAggregates sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN 
    RankedOrders ra ON ra.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey = p.p_partkey
    )
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND (sa.total_avail_qty IS NULL OR sa.avg_supply_cost <= 150.00)
ORDER BY 
    p.p_brand, p.p_name;
