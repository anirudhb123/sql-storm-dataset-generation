WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice
    FROM part
    WHERE p_size > 10

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice
    FROM part p
    INNER JOIN part_hierarchy ph ON p.p_partkey = ph.p_partkey
    WHERE p.p_retailprice < ph.p_retailprice
),
ranking AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        RANK() OVER (ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    INNER JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT
    ph.p_name,
    ph.p_size,
    ph.p_retailprice,
    r.s_name AS supplier_name,
    os.c_name AS customer_name,
    os.total_spent,
    os.order_count
FROM part_hierarchy ph
LEFT JOIN ranking r ON r.total_parts > 5
FULL OUTER JOIN order_summary os ON os.order_count > 3
WHERE ph.p_retailprice BETWEEN 50 AND 100
  AND os.total_spent IS NOT NULL
ORDER BY ph.p_retailprice DESC, os.total_spent ASC;
