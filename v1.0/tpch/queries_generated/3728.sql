WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationAgg AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acct_bal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_extendedprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-12-31'
)
SELECT 
    ns.n_name,
    ss.s_name,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue,
    COALESCE(SUM(od.l_quantity), 0) AS total_quantity,
    MAX(od.o_orderdate) AS last_order_date
FROM 
    SupplierStats ss
JOIN 
    NationAgg ns ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
        (SELECT DISTINCT l.l_partkey FROM OrderDetails od WHERE od.rn = 1))
LEFT JOIN 
    OrderDetails od ON ss.s_suppkey = od.l_partkey
WHERE 
    ns.supplier_count IS NOT NULL
GROUP BY 
    ns.n_name, ss.s_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC, last_order_date DESC;
