WITH RECURSIVE SupplierCTE AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerCTE AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = c.c_custkey
         AND o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01') AS order_count
    FROM
        customer c
    WHERE
        c.c_acctbal > 1000
),
PartSupplierCTE AS (
    SELECT
        p.p_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey
),
OrderProduct AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice - l.l_discount) AS total_revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_returnflag = 'N'
    GROUP BY
        o.o_orderkey
)
SELECT
    c.c_name,
    COALESCE(NULLIF(total_revenue, 0), 'No Revenue') AS revenue_status,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    p.p_name,
    r.r_name
FROM
    CustomerCTE c
LEFT JOIN
    OrderProduct o ON o.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN
    PartSupplierCTE p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (
        SELECT s.s_suppkey FROM SupplierCTE s WHERE s.rank <= 3))
LEFT JOIN
    nation n ON n.n_nationkey = c.c_nationkey
LEFT JOIN
    region r ON r.r_regionkey = n.n_regionkey
WHERE
    (c.order_count > 0 OR s.s_suppkey IS NULL)
    AND (p.total_supply_cost > 50000 OR p.total_supply_cost IS NULL)
ORDER BY
    c.c_name, revenue_status DESC
FETCH FIRST 10 ROWS ONLY;
