WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(ps.ps_availqty) DESC) AS rn,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
),
SelectedParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.total_availqty,
        rp.avg_supplycost,
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.rn <= (SELECT COUNT(*) FROM RankedParts) / 10
),
DistinctCustomers AS (
    SELECT DISTINCT 
        c.c_custkey,
        c.c_name
    FROM 
        customer c
    WHERE 
        NOT EXISTS (
            SELECT 1 FROM orders o WHERE o.o_custkey = c.c_custkey
        )
),
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_order_value,
        o.o_orderdate,
        o.o_custkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate IS NULL OR l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
)
SELECT 
    sp.p_partkey,
    sp.p_name,
    sp.total_availqty,
    sp.avg_supplycost,
    COUNT(DISTINCT oc.o_orderkey) AS order_count,
    AVG(os.net_order_value) AS avg_net_order_value
FROM 
    SelectedParts sp
LEFT JOIN 
    OrderSummaries os ON sp.p_partkey = os.o_custkey
LEFT JOIN 
    customer c ON c.c_custkey = os.o_custkey
LEFT JOIN 
    DISTINCTCustomers oc ON oc.c_custkey = os.o_custkey
WHERE 
    NOT (sp.total_availqty <= 100 AND oc.c_custkey IS NOT NULL)
GROUP BY 
    sp.p_partkey, sp.p_name, sp.total_availqty, sp.avg_supplycost
HAVING 
    avg_net_order_value IS NULL OR supplier_count > 2
ORDER BY 
    sp.avg_supplycost DESC, order_count ASC;
