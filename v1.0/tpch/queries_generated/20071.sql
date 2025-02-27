WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopTenOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        CASE 
            WHEN r.revenue_rank <= 10 THEN 'Top 10' 
            ELSE 'Others' 
        END AS revenue_status
    FROM 
        RankedOrders r
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalResults AS (
    SELECT 
        c.c_name,
        COALESCE(s.total_supply_cost, 0) AS supply_cost,
        COALESCE(o.total_revenue, 0) AS order_revenue,
        cs.order_count,
        cs.total_spent
    FROM 
        CustomerOrders cs
    LEFT JOIN 
        SupplierStats s ON cs.order_count > 0 AND s.unique_parts_count > 0
    LEFT JOIN 
        (
            SELECT 
                o.o_orderkey,
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
            FROM 
                orders o
            JOIN 
                lineitem l ON o.o_orderkey = l.l_orderkey
            GROUP BY 
                o.o_orderkey
            HAVING 
                SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
        ) o ON o.o_orderkey = cs.order_count
)
SELECT 
    f.c_name,
    f.supply_cost,
    f.order_revenue,
    CASE 
        WHEN f.total_spent IS NULL THEN 'No Orders'
        WHEN f.total_spent > 10000 THEN 'High Spender'
        ELSE 'Regular Spender'
    END AS spending_category
FROM 
    FinalResults f
WHERE 
    f.supply_cost IS NOT NULL OR f.order_revenue IS NOT NULL
ORDER BY 
    f.order_revenue DESC, f.supply_cost ASC
LIMIT 50;
