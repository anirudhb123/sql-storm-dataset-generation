WITH RECURSIVE SalesHistory AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
    UNION ALL
    SELECT 
        sh.c_custkey,
        sh.c_name,
        sh.total_spent + o.o_totalprice,
        sh.orders_count + 1
    FROM 
        SalesHistory sh
    JOIN 
        orders o ON sh.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
),
RankedNations AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS ranking
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
),
TopRegions AS (
    SELECT 
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_regionkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
FinalResults AS (
    SELECT 
        sh.c_name,
        sh.total_spent,
        n.n_name,
        tr.r_name,
        CASE 
            WHEN sh.total_spent >= 1000 THEN 'VIP'
            WHEN sh.total_spent < 1000 AND sh.total_spent > 0 THEN 'Regular'
            ELSE 'Non-Customer' 
        END AS customer_status
    FROM 
        SalesHistory sh
    JOIN 
        customer c ON sh.c_custkey = c.c_custkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        TopRegions tr ON n.n_regionkey = tr.r_regionkey
    WHERE 
        sh.total_spent IS NOT NULL
)
SELECT 
    fr.c_name,
    fr.total_spent,
    fr.n_name AS nation,
    fr.r_name AS region,
    fr.customer_status
FROM 
    FinalResults fr
WHERE 
    fr.customer_status != 'Non-Customer'
ORDER BY 
    fr.total_spent DESC
LIMIT 100;
