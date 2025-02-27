WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM
        CustomerSummary cs
    WHERE
        cs.total_spent > 10000
),
SupplierPartData AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        SUM(l.l_quantity) AS total_quantity
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY
        p.p_partkey, p.p_name, ps.ps_supplycost
)
SELECT
    r.r_name,
    ns.n_name,
    COALESCE(hvc.total_spent, 0) AS high_value_cust_spent,
    GROUP_CONCAT(DISTINCT spd.p_name ORDER BY spd.total_quantity DESC) AS popular_parts,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customer_count
FROM
    region r
JOIN
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN
    HighValueCustomers hvc ON ns.n_nationkey = hvc.c_custkey
LEFT JOIN
    SupplierPartData spd ON ns.n_nationkey = spd.ps_supplycost  -- Assuming some relation for demonstration
WHERE
    (hvc.total_spent IS NOT NULL OR hvc.total_spent IS NULL)
    AND (r.r_name LIKE 'Asia%' OR r.r_name IS NULL)
    AND (ns.n_name NOT IN ('Germany', 'France') OR ns.n_name IS NULL)
GROUP BY
    r.r_name, ns.n_name
ORDER BY
    high_value_cust_spent DESC
LIMIT 100;
