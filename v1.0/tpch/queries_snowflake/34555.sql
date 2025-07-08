
WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice, p_type, 0 AS level
    FROM part
    WHERE p_size <= 10

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice * 1.05, p.p_type, ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON ph.p_partkey = p.p_partkey
    WHERE p.p_size > 10
),
ranked_purchase AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS spend_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, r.r_name AS region_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.p_brand,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    rp.total_spent,
    rp.spend_rank,
    CASE 
        WHEN rp.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Regular Customer'
    END AS customer_status
FROM part_hierarchy ph
LEFT JOIN supplier_info s ON ph.p_partkey = s.s_suppkey
LEFT JOIN ranked_purchase rp ON s.s_suppkey = rp.c_custkey
WHERE ph.level < 3
ORDER BY ph.p_partkey, rp.spend_rank DESC;
