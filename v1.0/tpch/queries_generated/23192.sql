WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartStats AS (
    SELECT
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
NationalSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        SUM(ps_total.total_available) AS total_avail_qty
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        PartStats ps_total ON ps_total.p_partkey IN (
            SELECT p.p_partkey
            FROM part p
            JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
            WHERE ps.ps_availqty IS NOT NULL
        )
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    ns.unique_suppliers,
    ns.total_avail_qty,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    SUM(cs.total_orders) AS total_orders,
    AVG(cs.avg_order_value) AS avg_order_value,
    SUM(RANK() OVER (PARTITION BY r.r_regionkey ORDER BY NULLIF(ns.unique_suppliers, 0))) AS rank_summary,
    CASE 
        WHEN MAX(cs.last_order_date) IS NULL THEN 'No Orders'
        ELSE TO_CHAR(MAX(cs.last_order_date), 'YYYY-MM-DD')
    END AS last_order_date
FROM 
    region r
JOIN 
    NationalSummary ns ON r.r_regionkey = ns.n_nationkey
LEFT JOIN 
    CustomerOrderStats cs ON cs.c_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment <> 'NO_SEGMENT'
    )
GROUP BY 
    r.r_name, ns.unique_suppliers, ns.total_avail_qty
HAVING 
    ns.unique_suppliers > COALESCE((SELECT AVG(unique_suppliers) FROM NationalSummary), 0)
ORDER BY 
    r.r_name ASC, total_orders DESC;
