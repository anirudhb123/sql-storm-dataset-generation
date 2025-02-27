WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        s.*
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1 WHERE c1.c_mktsegment = c.c_mktsegment)
    GROUP BY 
        c.c_custkey
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FinalReport AS (
    SELECT 
        c.c_custkey,
        TOP.s_suppkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS sales_revenue,
        COALESCE(sd.total_avail_qty, 0) AS total_avail_qty,
        COALESCE(sd.avg_supply_cost, 0) AS avg_supply_cost,
        CASE 
            WHEN c.order_count > 5 THEN 'Gold' 
            WHEN c.order_count BETWEEEN 3 AND 5 THEN 'Silver' 
            ELSE 'Bronze' 
        END AS customer_tier
    FROM 
        CustomerOrders c
    LEFT JOIN 
        TopSuppliers TOP ON c.c_custkey = TOP.s_suppkey
    LEFT JOIN 
        lineitem lo ON lo.l_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_custkey = c.c_custkey)
    LEFT JOIN 
        SupplierDetails sd ON lo.l_partkey = sd.ps_partkey
    WHERE 
        c.total_spent > 1000
    GROUP BY 
        c.c_custkey, TOP.s_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT fr.c_custkey) AS customer_count,
    AVG(fr.sales_revenue) AS avg_revenue,
    SUM(fr.total_avail_qty) AS total_available_quantity,
    MAX(fr.avg_supply_cost) AS highest_avg_supply_cost
FROM 
    FinalReport fr
JOIN 
    customer c ON fr.c_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%Europe%'
    AND fr.customer_tier = 'Gold'
GROUP BY 
    r.r_name
ORDER BY 
    avg_revenue DESC;
