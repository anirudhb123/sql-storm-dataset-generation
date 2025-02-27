WITH Supplier_Part_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Order_Summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_ordered
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
Nation_Region_CTE AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        COUNT(*) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(ss.total_avail_qty, 0) AS total_available_qty,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    SUM(os.total_order_value) AS total_order_value,
    SUM(os.unique_parts_ordered) AS unique_parts_per_order
FROM 
    Nation_Region_CTE n
LEFT JOIN 
    Supplier_Part_Summary ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN 
    Order_Summary os ON n.n_nationkey = os.o_custkey
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(os.total_order_value) > 10000
ORDER BY 
    n.n_name, r.r_name DESC;
