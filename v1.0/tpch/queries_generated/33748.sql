WITH RECURSIVE Nation_Suppliers AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        s.s_suppkey, 
        ROUND(s.s_acctbal, 2) AS supplier_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal > 1000

    UNION ALL

    SELECT 
        n.n_nationkey, 
        n.n_name, 
        s.s_suppkey, 
        ROUND(s.s_acctbal, 2) AS supplier_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal <= 1000 
        AND EXISTS (
            SELECT 1 
            FROM Nation_Suppliers ns 
            WHERE ns.n_nationkey = n.n_nationkey 
            AND ns.supplier_balance < s.s_acctbal
        )
),
Part_Supplier_Stats AS (
    SELECT 
        p.p_partkey, 
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) as total_available_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS distinct_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey 
    GROUP BY 
        p.p_partkey
),
Ranked_Orders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, 
        o.o_orderpriority
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT ns.s_suppkey) AS supplier_count,
    ps.p_partkey,
    ps.avg_supply_cost,
    ps.total_available_qty,
    ro.o_orderkey,
    ro.total_price,
    ro.price_rank
FROM 
    Nation_Suppliers ns
JOIN 
    Part_Supplier_Stats ps ON ns.s_suppkey = (SELECT ps2.ps_suppkey FROM partsupp ps2 WHERE ps2.ps_partkey = ps.p_partkey ORDER BY ps2.ps_supplycost LIMIT 1)
LEFT JOIN 
    Ranked_Orders ro ON ns.s_suppkey = (SELECT ps3.ps_suppkey FROM partsupp ps3 WHERE ps3.ps_partkey = ps.p_partkey ORDER BY ps3.ps_availqty DESC LIMIT 1)
WHERE 
    ns.supplier_balance > 2500 AND (ro.price_rank <= 5 OR ro.total_price IS NULL)
GROUP BY 
    ns.n_name, ps.p_partkey, ps.avg_supply_cost, ps.total_available_qty, ro.o_orderkey, ro.total_price, ro.price_rank
HAVING 
    SUM(ps.total_available_qty) > 1000 
ORDER BY 
    ns.n_name, ps.p_partkey;
