WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.o_orderstatus,
    p.p_name,
    p.total_available_qty,
    rp.total_supply_cost,
    sp.total_parts,
    COALESCE(sp.avg_supply_cost, 0) AS avg_supplier_cost
FROM 
    RankedOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    PartStats p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    SupplierPerformance sp ON p.supplier_count > 0
WHERE 
    o.o_totalprice > (SELECT AVG(o_totalprice) FROM RankedOrders)
    AND (
        (l.l_returnflag = 'N' AND l.l_linestatus = 'F') 
        OR (l.l_returnflag = 'Y' AND l.l_linestatus = 'O')
    )
ORDER BY 
    o.o_orderdate DESC, o.o_orderkey;
