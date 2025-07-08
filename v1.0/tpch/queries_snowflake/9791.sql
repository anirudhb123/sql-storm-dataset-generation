WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RegionNationSummary AS (
    SELECT 
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_availqty) AS total_available_parts
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    ra.region_name,
    ra.nation_name,
    sa.s_name,
    sa.total_supply_cost,
    cos.order_count,
    cos.total_spent,
    cos.avg_order_value
FROM 
    RegionNationSummary ra
JOIN 
    SupplierAggregates sa ON ra.nation_name IN (SELECT n_name FROM nation WHERE n_nationkey = sa.s_suppkey)
JOIN 
    CustomerOrderSummary cos ON cos.c_custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = ra.nation_name))
ORDER BY 
    ra.region_name, sa.total_supply_cost DESC, cos.total_spent DESC;
