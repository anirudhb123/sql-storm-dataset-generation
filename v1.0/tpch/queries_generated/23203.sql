WITH RecursivePartCounts AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
MaxCostSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        partsupp ps
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
RegionNations AS (
    SELECT 
        r.r_name,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(s.s_name, ', ') AS supplier_names
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    p.p_name,
    rc.supplier_count,
    rc.total_avail_qty,
    m.s_psupplycost,
    r.supplier_count AS region_supplier_count,
    r.supplier_names,
    hv.o_totalprice
FROM 
    RecursivePartCounts rc
JOIN 
    MaxCostSupplier m ON rc.p_partkey = m.ps_partkey AND m.rn = 1
LEFT JOIN 
    RegionNations r ON r.supplier_count > rc.supplier_count
JOIN 
    HighValueOrders hv ON hv.o_orderkey IN (SELECT l.l_orderkey 
                                             FROM lineitem l 
                                             WHERE l.l_partkey = rc.p_partkey)
WHERE 
    rc.total_avail_qty IS NOT NULL 
    AND m.ps_supplycost IS NOT NULL 
    AND (m.ps_supplycost * 100 / NULLIF(hv.o_totalprice, 0)) < 50
ORDER BY 
    rc.supplier_count DESC, m.ps_supplycost ASC;
