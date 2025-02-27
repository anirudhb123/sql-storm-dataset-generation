WITH SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS total_suppliers,
        SUM(s_acctbal) AS total_account_balance,
        AVG(s_acctbal) AS avg_account_balance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'P') -- for open or pending orders
    GROUP BY 
        c.c_custkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers_per_part
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_ordered
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
    GROUP BY 
        l.l_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        ot.total_revenue,
        CASE 
            WHEN ot.total_revenue > 10000 THEN 'High'
            WHEN ot.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS order_value_category
    FROM 
        OrderLineDetails ot 
    JOIN 
        orders o ON o.o_orderkey = ot.l_orderkey
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        COALESCE(ss.total_suppliers, 0) AS total_suppliers,
        COALESCE(cs.total_orders, 0) AS total_orders,
        COALESCE(ps.total_suppliers_per_part, 0) AS total_suppliers_per_part,
        COALESCE(tv.order_value_category, 'None') AS order_value_category
    FROM 
        region r
    LEFT JOIN 
        SupplierStats ss ON r.r_regionkey = ss.s_nationkey
    LEFT JOIN 
        CustomerOrders cs ON cs.c_custkey IN (
            SELECT c.c_custkey
            FROM customer c
            WHERE c.c_nationkey = r.r_regionkey
        )
    LEFT JOIN 
        PartDetails ps ON ps.p_partkey IN (
            SELECT ps.ps_partkey
            FROM partsupp ps
            WHERE ps.ps_supplycost > 100
        )
    LEFT JOIN 
        HighValueOrders tv ON tv.o_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o 
            WHERE o.o_totalprice IS NOT NULL
        )
)
SELECT 
    region_name,
    total_suppliers,
    total_orders,
    total_suppliers_per_part,
    COUNT(DISTINCT order_value_category) AS distinct_order_categories
FROM 
    FinalReport
WHERE 
    total_suppliers > 0 OR total_orders > 0
GROUP BY 
    region_name, total_suppliers, total_orders, total_suppliers_per_part
ORDER BY 
    region_name ASC, total_orders DESC;
