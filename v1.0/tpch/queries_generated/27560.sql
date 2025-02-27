WITH PartSupplierInfo AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_name,
        CASE
            WHEN ps.ps_availqty < 50 THEN 'Low Stock'
            WHEN ps.ps_availqty BETWEEN 50 AND 150 THEN 'Moderate Stock'
            ELSE 'High Stock'
        END AS stock_status
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        CASE 
            WHEN SUM(o.o_totalprice) < 1000 THEN 'Bronze'
            WHEN SUM(o.o_totalprice) BETWEEN 1000 AND 5000 THEN 'Silver'
            ELSE 'Gold'
        END AS customer_tier
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    psi.supplier_part_name,
    psi.ps_availqty,
    psi.ps_supplycost,
    cos.c_name AS customer_name,
    cos.total_orders,
    cos.total_spent,
    cos.last_order_date,
    cos.customer_tier
FROM
    PartSupplierInfo psi
JOIN
    CustomerOrderSummary cos ON psi.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderstatus = 'O'
    )
ORDER BY
    cos.customer_tier DESC, 
    psi.ps_supplycost ASC;
