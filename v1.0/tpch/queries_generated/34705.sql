WITH RECURSIVE SupplierPartCTE AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
CustomerOrderCTE AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS cust_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2023-12-31'
    GROUP BY
        o.o_orderkey, o.o_custkey
)
SELECT
    c.c_name,
    SUM(sp.ps_supplycost) AS total_supply_cost,
    COALESCE(MAX(co.total_revenue), 0) AS max_order_revenue,
    COUNT(DISTINCT sp.ps_partkey) AS unique_parts_supplied,
    COUNT(DISTINCT co.o_orderkey) FILTER (WHERE co.cust_rank = 1) AS highest_value_orders
FROM
    supplier s
LEFT JOIN
    SupplierPartCTE sp ON s.s_suppkey = sp.ps_suppkey AND sp.rn <= 5
LEFT JOIN
    customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN
    CustomerOrderCTE co ON c.c_custkey = co.o_custkey
WHERE
    s.s_acctbal IS NOT NULL
    AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
GROUP BY
    c.c_name
ORDER BY
    total_supply_cost DESC
LIMIT 10;
