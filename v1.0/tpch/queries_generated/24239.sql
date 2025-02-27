WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND sh.level < 5
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
part_supplier_data AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey
),
ranked_customers AS (
    SELECT 
        cus.c_custkey,
        cus.order_count,
        cus.total_spent,
        RANK() OVER (ORDER BY cus.total_spent DESC) AS spender_rank
    FROM customer_order_summary cus
)
SELECT 
    ph.p_name,
    ph.total_available,
    ph.avg_cost,
    cs.c_custkey,
    cs.order_count,
    cs.total_spent,
    cs.spender_rank,
    CASE 
        WHEN cs.spender_rank <= 10 THEN 'Top Spender'
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE 'Regular Customer'
    END AS customer_segment,
    COALESCE(suppliers, 'No Suppliers') AS suppliers,
    CASE WHEN cs.last_order_date IS NULL THEN 'Did not order' ELSE TO_CHAR(cs.last_order_date, 'MM-DD-YYYY') END AS last_order
FROM part_supplier_data ph
LEFT JOIN ranked_customers cs ON cs.c_custkey = (SELECT DISTINCT c.c_custkey
    FROM customer c 
    WHERE c.c_name LIKE '%Acme%' OR c.c_address LIKE '%Unknown%' LIMIT 1)
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ph.p_partkey ORDER BY ps.ps_availqty DESC LIMIT 1)
WHERE ph.total_available IS NOT NULL
ORDER BY ph.avg_cost DESC, cs.total_spent DESC NULLS LAST
LIMIT 100;
