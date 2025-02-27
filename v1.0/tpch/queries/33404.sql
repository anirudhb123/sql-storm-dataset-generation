
WITH RECURSIVE supply_part_data AS (
    SELECT
        ps_partkey,
        SUM(ps_availqty) AS total_available,
        AVG(ps_supplycost) AS avg_supply_cost
    FROM
        partsupp
    GROUP BY
        ps_partkey
    HAVING
        SUM(ps_availqty) > 100
),
customer_order_summary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey, c.c_name
),
nation_total_details AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(s.s_suppkey) AS total_suppliers,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(s.s_acctbal) AS total_account_balance
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        n.n_nationkey, n.n_name
)
SELECT
    nt.n_name,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    spd.total_available,
    spd.avg_supply_cost,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS spending_category,
    nt.total_suppliers,
    nt.total_parts,
    nt.total_account_balance
FROM
    customer_order_summary cs
JOIN
    nation_total_details nt ON nt.n_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name = cs.c_name 
        LIMIT 1
    )
LEFT JOIN
    supply_part_data spd ON spd.ps_partkey = (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 50 
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
JOIN
    region r ON nt.n_nationkey = r.r_regionkey
WHERE
    r.r_name = 'ASIA' 
    AND cs.total_spent IS NOT NULL
ORDER BY
    cs.total_spent DESC, 
    nt.n_name ASC;
