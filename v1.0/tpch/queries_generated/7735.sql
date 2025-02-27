WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_avail,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS brand_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.total_avail,
    rp.avg_supply_cost,
    ts.s_name AS top_supplier,
    co.c_name AS top_customer,
    co.total_spent
FROM RankedParts rp
LEFT JOIN TopSuppliers ts ON rp.p_brand = ts.s_nationkey
LEFT JOIN CustomerOrders co ON co.order_count = (SELECT MAX(order_count) FROM CustomerOrders)
WHERE rp.brand_rank <= 3
ORDER BY rp.total_avail DESC, co.total_spent DESC
LIMIT 50;
