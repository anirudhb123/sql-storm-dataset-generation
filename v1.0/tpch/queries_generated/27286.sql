WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, COUNT(ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
EnhancedInfo AS (
    SELECT si.s_suppkey, si.s_name, ci.c_name, si.total_parts, ci.total_spent,
           COALESCE(r.r_name, 'Unknown') AS region_name
    FROM SupplierInfo si
    LEFT JOIN nation n ON si.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN CustomerInfo ci ON si.total_supply_cost > ci.total_spent
)
SELECT 
    e.s_suppkey,
    e.s_name,
    e.c_name,
    e.total_parts,
    e.total_spent,
    e.region_name,
    LENGTH(e.s_name) AS name_length,
    SUBSTRING_INDEX(e.s_name, ' ', -1) AS last_name_part,
    CONCAT(e.s_name, ' - ', e.c_name) AS supplier_customer_combined
FROM EnhancedInfo e
WHERE e.total_parts > 20
ORDER BY e.total_spent DESC, e.total_parts ASC
LIMIT 10;
