WITH OrderedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_revenue,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
    FROM
        part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        p.p_retailprice > 50.00
    GROUP BY
        p.p_partkey, p.p_name, s.s_name
)
SELECT
    *,
    CONCAT('Part: ', p_name, ' | Supplier: ', supplier_name, ' | Orders: ', order_count, ' | Total Quantity: ', total_quantity, ' | Total Revenue: ', total_revenue, ' | Nations Supplied: ', nations_supplied) AS summary
FROM
    OrderedParts
ORDER BY
    total_revenue DESC
LIMIT 10;
