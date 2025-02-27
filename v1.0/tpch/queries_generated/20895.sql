WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost) DESC) AS part_rank
    FROM
        part p
    LEFT JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_mfgr, p.p_type
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus IN ('F', 'P') -- only finished or processing orders
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders) -- above average spending
),
SupplierCosts AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
)
SELECT
    r.r_name,
    np.n_nationkey,
    np.n_name,
    rp.p_name,
    rp.total_avail_qty,
    hc.total_spent,
    CASE 
        WHEN hc.total_spent IS NULL THEN 'No Purchases'
        WHEN hc.total_spent > 10000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_type,
    COALESCE(SUM(sc.total_cost), 0) AS supplier_sum
FROM 
    region r
JOIN 
    nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN 
    RankedParts rp ON np.n_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name LIKE CONCAT('%', rp.p_mfgr, '%')
        FETCH FIRST 1 ROWS ONLY
    )
LEFT JOIN 
    HighValueCustomers hc ON hc.c_custkey IN (
        SELECT DISTINCT o.o_custkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_partkey = rp.p_partkey
    )
LEFT JOIN 
    SupplierCosts sc ON sc.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = rp.p_partkey
    )
GROUP BY
    r.r_name, np.n_nationkey, np.n_name, rp.p_name, hc.total_spent
HAVING
    SUM(rp.total_avail_qty) IS NOT NULL
ORDER BY
    r.r_name, customer_type DESC, rp.total_avail_qty DESC; 
