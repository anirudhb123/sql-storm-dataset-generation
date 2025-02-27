WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATEADD(month, -12, GETDATE())
),
CustomerNation AS (
    SELECT
        c.c_custkey,
        n.n_name,
        CASE
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal < 0 THEN 'Negative Balance'
            ELSE 'Positive Balance'
        END AS balance_status
    FROM
        customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
SupplierPartAvailability AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
    HAVING
        SUM(ps.ps_availqty) > 0
),
ImportantSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_comment, ''), 'No comment provided') AS safe_comment
    FROM
        supplier s
    WHERE
        EXISTS (
            SELECT 1
            FROM SupplierPartAvailability spa
            WHERE spa.ps_suppkey = s.s_suppkey
        )
),
OrderLineCounts AS (
    SELECT
        l.l_orderkey,
        COUNT(*) AS item_count
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
),
FinalStats AS (
    SELECT
        cn.n_name,
        COUNT(DISTINCT co.c_custkey) AS customer_count,
        SUM(CASE WHEN lo.o_orderstatus = 'F' THEN lo.o_totalprice ELSE 0 END) AS final_order_value,
        AVG(il.item_count) AS avg_lineitem_per_order
    FROM
        CustomerNation cn
    LEFT JOIN RankedOrders lo ON cn.c_custkey = lo.o_orderkey
    LEFT JOIN OrderLineCounts il ON il.l_orderkey = lo.o_orderkey
    GROUP BY
        cn.n_name
    HAVING
        AVG(il.item_count) IS NOT NULL
)
SELECT
    fs.n_name,
    fs.customer_count,
    fs.final_order_value,
    fs.avg_lineitem_per_order,
    COALESCE(spa.total_avail_qty, 0) AS available_parts
FROM
    FinalStats fs
LEFT JOIN (
    SELECT
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM
        part p
    JOIN SupplierPartAvailability ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey
    HAVING
        SUM(ps.ps_availqty) >= 5
) spa ON spa.p_partkey = fs.customer_count % 100
ORDER BY
    fs.customer_count DESC,
    fs.final_order_value ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
