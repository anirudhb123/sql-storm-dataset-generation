WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS num_orders,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_analysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    cs.c_name,
    cs.total_spent,
    ss.total_available,
    ss.average_supply_cost,
    la.total_value,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Finalized'
        WHEN r.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_description
FROM 
    ranked_orders r
LEFT JOIN 
    customer_orders cs ON r.o_orderkey = cs.c_custkey
LEFT JOIN 
    lineitem_analysis la ON r.o_orderkey = la.l_orderkey
LEFT JOIN 
    supplier_summary ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_orderkey = r.o_orderkey 
        LIMIT 1
    )
WHERE 
    COALESCE(cs.total_spent, 0) > 1000 
    AND (ss.total_available IS NULL OR ss.average_supply_cost < 50)
ORDER BY 
    r.o_totalprice DESC, r.o_orderdate;