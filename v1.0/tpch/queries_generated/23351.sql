WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn,
        SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY s.s_suppkey) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 1000
),

FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size' 
            ELSE CAST(p.p_size AS VARCHAR)
        END AS size_label,
        COUNT(ps.ps_partkey) AS part_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_size
    HAVING COUNT(ps.ps_partkey) > 1
),

FinalOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND
        o.o_orderdate >= DATE '2020-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
    ORDER BY o.o_totalprice DESC
)

SELECT 
    r.s_suppkey,
    r.s_name,
    p.p_name,
    p.size_label,
    o.o_orderkey,
    o.o_totalprice,
    o.order_year,
    COALESCE(o.line_item_count, 0) AS line_item_count,
    r.total_supply_cost
FROM RankedSuppliers r
FULL OUTER JOIN FilteredParts p ON r.s_suppkey = p.p_partkey
LEFT JOIN FinalOrders o ON r.s_suppkey = o.o_orderkey
WHERE 
    r.rn <= 3 OR 
    (p.part_count IS NOT NULL AND r.total_supply_cost > 50000)
ORDER BY r.s_suppkey, o.o_orderkey
LIMIT 10 OFFSET 5;

