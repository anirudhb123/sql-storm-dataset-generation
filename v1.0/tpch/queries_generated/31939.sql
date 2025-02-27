WITH RECURSIVE Part_Supplier_Avg AS (
    SELECT
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey
),
Customer_Orders AS (
    SELECT
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.custkey
),
Nation_Supplier AS (
    SELECT
        n.n_name,
        SUM(ps.ps_availqty) AS total_available
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        n.n_name
),
Ranked_Customer_Orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(co.total_orders, 0) AS total_orders,
        COALESCE(co.total_spent, 0) AS total_spent,
        RANK() OVER (ORDER BY COALESCE(co.total_spent, 0) DESC) AS spending_rank
    FROM
        customer c
    LEFT JOIN
        Customer_Orders co ON c.c_custkey = co.c_custkey
)
SELECT
    r.r_name,
    ns.total_available,
    p.p_name,
    psa.avg_supplycost,
    rco.c_name,
    rco.total_orders,
    rco.total_spent,
    rco.spending_rank
FROM
    region r
LEFT JOIN
    Nation_Supplier ns ON r.r_regionkey = (
        SELECT n.n_regionkey FROM nation n WHERE n.n_name = r.r_name
    )
LEFT JOIN
    part p ON p.p_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        WHERE ps.ps_availqty > 100
    )
LEFT JOIN
    Part_Supplier_Avg psa ON p.p_partkey = psa.p_partkey
LEFT JOIN
    Ranked_Customer_Orders rco ON rco.total_spent > (
        SELECT AVG(total_spent) FROM Ranked_Customer_Orders
    )
WHERE
    ns.total_available IS NOT NULL
ORDER BY
    rco.spending_rank, ns.total_available DESC
LIMIT 50;
