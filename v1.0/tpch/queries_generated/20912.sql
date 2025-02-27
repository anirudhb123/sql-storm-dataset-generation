WITH PartStats AS (
    SELECT 
        p.p_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
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
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    r.r_name,
    p.p_name,
    ps.total_avail_qty,
    co.order_count,
    co.total_spent,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.total_spent > 1000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_segment,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY ps.avg_supply_cost DESC) AS rank_by_supply_cost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    PartStats ps ON ps.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_container = 'BOX')
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey 
                                           FROM customer c 
                                           WHERE c.c_nationkey = n.n_nationkey 
                                           ORDER BY c.c_acctbal DESC 
                                           LIMIT 1)
WHERE 
    ps.total_avail_qty IS NOT NULL 
    AND (co.order_count > 5 OR co.total_spent > 500)
ORDER BY 
    r.r_name, n.n_name, ps.avg_supply_cost DESC;
