WITH RECURSIVE CTE_Supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey,
        ss.s_name,
        ss.s_nationkey,
        ss.s_acctbal,
        level + 1
    FROM 
        partsupp ps
    JOIN 
        supplier ss ON ps.ps_suppkey = ss.s_suppkey
    JOIN 
        CTE_Supplier cte ON cte.s_suppkey = ps.ps_suppkey
    WHERE 
        ss.s_acctbal > 500
),
CustomerOrder AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
    GROUP BY 
        c.c_custkey, c.c_name
),
MaxSpender AS (
    SELECT 
        MAX(total_spent) AS max_spent 
    FROM 
        CustomerOrder
),
SupplierStats AS (
    SELECT 
        ns.n_name,
        COUNT(DISTINCT cs.c_custkey) AS customer_count,
        AVG(cs.total_spent) AS average_spent,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        nation ns
    JOIN 
        supplier s ON ns.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        CustomerOrder cs ON s.s_suppkey = cs.c_custkey
    WHERE 
        cs.total_spent > (SELECT max_spent FROM MaxSpender)
    GROUP BY 
        ns.n_name
)
SELECT 
    r.r_name,
    COALESCE(ss.customer_count, 0) AS customer_count,
    COALESCE(ss.average_spent, 0) AS average_spent,
    CASE 
        WHEN ss.total_available_qty IS NOT NULL 
        THEN SUM(ps.ps_availqty) OVER (PARTITION BY ns.n_nationkey) 
        ELSE NULL 
    END AS national_supply_qty
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ss ON ss.n_name = n.n_name
LEFT JOIN 
    partsupp ps ON ss.total_available_qty = ps.ps_availqty
ORDER BY 
    r.r_name;
