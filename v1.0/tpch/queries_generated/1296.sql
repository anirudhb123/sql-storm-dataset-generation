WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartRankings AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        DENSE_RANK() OVER (ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS price_rank
    FROM 
        part p
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)

SELECT 
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    ps.p_name AS part_name,
    ss.total_available_qty,
    cs.total_spent,
    pr.price_rank
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON cs.order_count > 5 AND ss.total_available_qty IS NOT NULL
JOIN 
    PartRankings pr ON pr.price_rank <= 10
JOIN 
    partsupp ps ON ps.ps_partkey = pr.p_partkey AND ps.ps_supplycost < ss.avg_supply_cost
WHERE 
    cs.total_spent IS NOT NULL
ORDER BY 
    cs.total_spent DESC, ss.total_available_qty ASC
LIMIT 20;
