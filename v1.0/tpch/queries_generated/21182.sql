WITH RECURSIVE price_variance AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_supplycost, 
        LEAD(ps_supplycost) OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost) AS next_supplycost,
        (LEAD(ps_supplycost) OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost) - ps_supplycost) AS cost_difference
    FROM partsupp
), ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_name, 
        p.p_brand, 
        p.p_container,
        pv.cost_difference,
        DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY pv.cost_difference DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN price_variance pv ON ps.ps_partkey = pv.ps_partkey AND ps.ps_suppkey = pv.ps_suppkey
    WHERE 
        pv.cost_difference IS NOT NULL 
        AND pv.cost_difference > 0
), notable_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        c.c_nationkey,
        COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
    HAVING COUNT(l.l_orderkey) > 1
), high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    r.supplier_rank,
    r.s_name,
    r.p_name,
    r.p_brand,
    r.p_container,
    no.o_orderkey,
    no.o_totalprice,
    hc.c_name,
    hc.c_acctbal
FROM ranked_suppliers r
JOIN notable_orders no ON r.s_suppkey = no.o_orderkey
JOIN high_value_customers hc ON no.c_nationkey = hc.c_custkey
WHERE 
    r.supplier_rank <= 5 
    AND (hc.c_acctbal IS NULL OR hc.c_acctbal > 1000)
ORDER BY 
    r.supplier_rank ASC, 
    no.o_totalprice DESC, 
    hc.c_acctbal ASC;
