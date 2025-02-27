WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS suppliers_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
),
CombinedResults AS (
    SELECT 
        ss.s_name,
        os.c_name,
        pd.p_name,
        pd.suppliers_count,
        os.total_spent,
        os.avg_order_value,
        pd.avg_supply_cost,
        ro.o_orderkey,
        ro.o_orderdate
    FROM 
        SupplierStats ss
    JOIN 
        PartDetails pd ON ss.unique_parts_count > 2 
    CROSS JOIN 
        OrderSummary os 
    LEFT JOIN 
        RankedOrders ro ON ro.o_orderkey IS NOT NULL
)

SELECT DISTINCT
    cr.s_name,
    cr.c_name,
    cr.p_name,
    COALESCE(cr.total_spent, 0) AS total_spent,
    COALESCE(cr.avg_order_value, 0) AS avg_order_value,
    cr.suppliers_count,
    cr.avg_supply_cost,
    cr.o_orderdate,
    CASE 
        WHEN cr.o_orderdate < CURRENT_DATE - INTERVAL '30 days' THEN 'Old Order'
        ELSE 'Recent Order'
    END AS order_age,
    cr.o_orderkey
FROM 
    CombinedResults cr
WHERE 
    cr.total_spent > 1000
ORDER BY 
    cr.total_spent DESC, 
    cr.suppliers_count DESC;
