WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_items_count,
        o.o_orderpriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_orderpriority
), RankedOrders AS (
    SELECT 
        os.*, 
        RANK() OVER (PARTITION BY os.o_orderpriority ORDER BY os.total_revenue DESC) AS rn
    FROM 
        OrderSummary os
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.n_nationkey) AS nations_count,
    SUM(COALESCE(ss.total_parts, 0)) AS total_parts_supplied,
    SUM(CASE WHEN ro.rn = 1 THEN ro.total_revenue ELSE 0 END) AS top_revenue_order,
    STRING_AGG(s.s_name, ', ') AS supplier_names
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = s.s_suppkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderpriority LIKE '%HIGH%' AND ro.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey IN (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_acctbal IS NOT NULL
        )
    )
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
