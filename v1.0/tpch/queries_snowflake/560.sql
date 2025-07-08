
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) OVER (PARTITION BY n.n_regionkey) AS avg_acctbal_by_region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey, s.s_acctbal
), 
CustomerOrderStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date,
        MIN(o.o_orderdate) AS first_order_date,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    ss.s_name,
    ss.part_count,
    ss.total_supply_cost,
    co.total_orders,
    co.order_count,
    co.last_order_date,
    co.first_order_date
FROM 
    SupplierStats ss
FULL OUTER JOIN 
    CustomerOrderStats co ON ss.s_suppkey = co.c_custkey
WHERE 
    (ss.part_count > 5 OR co.order_count > 3)
    AND (ss.total_supply_cost IS NOT NULL OR co.total_orders IS NOT NULL)
ORDER BY 
    ss.total_supply_cost DESC NULLS LAST, 
    co.order_count DESC NULLS LAST;
