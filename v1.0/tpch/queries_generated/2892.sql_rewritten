WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), AvgRevenue AS (
    SELECT 
        AVG(total_revenue) AS avg_revenue
    FROM 
        OrderDetails
), CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT ps.ps_partkey) AS part_count,
    COALESCE(SUM(sp.total_supply_cost), 0) AS total_supply_cost,
    AVG(cs.total_spent) AS avg_spent,
    CASE 
        WHEN AVG(cs.total_spent) > (SELECT avg_revenue FROM AvgRevenue) THEN 'Above Average'
        ELSE 'Below Average'
    END AS spending_category
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    CustomerStats cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey LIMIT 1)
LEFT JOIN 
    SupplierParts sp ON sp.s_suppkey = s.s_suppkey
GROUP BY 
    ns.n_name
ORDER BY 
    part_count DESC, avg_spent DESC;