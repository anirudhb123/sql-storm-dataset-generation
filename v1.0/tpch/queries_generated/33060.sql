WITH RECURSIVE CTE_Nations AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment 
    FROM nation 
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment 
    FROM nation n
    JOIN CTE_Nations c ON n.n_regionkey = c.n_regionkey
)
, CTE_SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(SUM(o.o_totalprice), 0) AS total_order_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' - ', p.p_brand) ORDER BY p.p_name) AS product_list,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    MAX(s.s_acctbal) AS max_supplier_balance
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN part p ON l.l_partkey = p.p_partkey
LEFT JOIN CTE_SupplierStats ss ON ss.s_suppkey = l.l_suppkey
LEFT JOIN CTE_Nations cn ON cn.n_nationkey = c.c_nationkey
WHERE o.o_orderstatus IN ('O', 'F')
AND o.o_orderdate >= DATEADD(YEAR, -1, CURRENT_DATE)
GROUP BY c.c_custkey, c.c_name
HAVING total_order_value > (SELECT AVG(total_supply_cost) FROM CTE_SupplierStats WHERE rn = 1)
ORDER BY total_order_value DESC
LIMIT 10;
