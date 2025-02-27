WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as acctbal_rank
    FROM
        supplier s
    WHERE
        s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) as total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus != 'F' AND
        o.o_totalprice > 1000
    GROUP BY
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
),
LineItemData AS (
    SELECT
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        CASE 
            WHEN l.l_returnflag = 'Y' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) as line_item_number
    FROM
        lineitem l
    WHERE
        l.l_discount > 0.05
)
SELECT
    ps.ps_partkey,
    p.p_name,
    r.r_name AS supplier_region,
    ss.s_name AS top_supplier,
    c.c_name AS high_value_customer,
    SUM(ld.l_extendedprice * (1 - ld.l_discount)) AS potential_revenue,
    CASE
        WHEN SUM(ld.l_quantity) > 100 THEN 'High Volume'
        ELSE 'Regular Volume'
    END AS volume_category
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    RankedSuppliers ss ON ps.ps_suppkey = ss.s_suppkey AND ss.acctbal_rank = 1
LEFT JOIN
    nation n ON ss.s_nationkey = n.n_nationkey
LEFT JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    LineItemData ld ON ld.l_partkey = p.p_partkey
LEFT JOIN
    HighValueCustomers c ON ld.l_orderkey = (SELECT MAX(o_orderkey) FROM orders WHERE o_custkey = c.c_custkey)
WHERE
    p.p_retailprice BETWEEN 50 AND 500 AND
    ld.return_status = 'Not Returned'
GROUP BY
    ps.ps_partkey, p.p_name, r.r_name, ss.s_name, c.c_name
HAVING
    potential_revenue > 10000
ORDER BY
    potential_revenue DESC, volume_category;
