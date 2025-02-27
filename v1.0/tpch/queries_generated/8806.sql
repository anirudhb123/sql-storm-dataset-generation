WITH SupplierPartStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionNationStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
)
SELECT 
    rns.r_name,
    rns.total_suppliers,
    cps.c_name,
    cps.total_orders,
    cps.avg_order_value,
    sps.s_name,
    sps.total_available,
    sps.total_supply_cost
FROM 
    RegionNationStats rns
LEFT JOIN 
    CustomerOrderStats cps ON cps.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        JOIN nation n ON c.c_nationkey = n.n_nationkey
        WHERE n.n_regionkey = rns.r_regionkey
    )
LEFT JOIN 
    SupplierPartStats sps ON sps.s_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE s.s_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_regionkey = rns.r_regionkey
        )
    )
ORDER BY 
    rns.r_name, cps.total_orders DESC, sps.total_supply_cost DESC;
