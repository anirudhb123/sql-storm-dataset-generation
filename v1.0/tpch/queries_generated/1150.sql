WITH SupplierStats AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
)
SELECT 
    co.c_name AS customer_name,
    ns.n_name AS nation_name,
    ss.s_name AS supplier_name,
    ss.total_available_quantity AS supplier_total_available,
    ss.avg_supply_cost AS supplier_avg_cost,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.order_rank,
    COALESCE(ss.unique_parts_supplied, 0) AS unique_parts_supplied
FROM 
    CustomerOrders co
JOIN 
    Nations ns ON co.c_nationkey = ns.n_nationkey
LEFT JOIN 
    SupplierStats ss ON ns.n_nationkey = ss.s_nationkey
JOIN 
    RankedOrders ro ON co.c_custkey = ro.o_orderkey
WHERE 
    co.total_spent > 5000 
    AND (ss.total_available_quantity IS NULL OR ss.avg_supply_cost < 20.00)
ORDER BY 
    co.total_spent DESC, 
    ss.avg_supply_cost ASC;
