
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ps.p_name,
    COALESCE(r.total_cost, 0) AS total_cost,
    ps.supplier_count,
    ps.avg_supply_cost,
    od.total_revenue,
    od.item_count,
    od.o_orderdate
FROM 
    PartStats ps
LEFT JOIN 
    RankedSuppliers r ON ps.supplier_count = r.rank
LEFT JOIN 
    OrderDetails od ON ps.p_partkey = (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = od.o_orderkey 
        FETCH FIRST 1 ROW ONLY
    )
WHERE 
    ps.supplier_count > 0 
ORDER BY 
    total_cost DESC, ps.p_name
LIMIT 100;
