WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM
        part p
    WHERE
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container LIKE '%BOX%')
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_address, s.s_nationkey
    HAVING
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
RecentOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= CURRENT_DATE - INTERVAL '60 days'
    GROUP BY
        o.o_orderkey, o.o_totalprice, o.o_orderdate
),
StringAggregation AS (
    SELECT
        r.r_name,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        RecentOrders ro ON ro.o_orderkey = ps.ps_partkey  -- Assuming mapping in a hypothetical sense
    JOIN
        lineitem l ON ro.o_orderkey = l.l_orderkey
    WHERE
        p.p_brand IN (SELECT DISTINCT p_brand FROM RankedParts WHERE rn <= 5)
    GROUP BY
        r.r_name
)
SELECT
    s.r_name,
    s.part_names,
    s.order_count,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts
FROM
    StringAggregation s
JOIN
    supplier sup ON sup.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
GROUP BY
    s.r_name, s.part_names, s.order_count
ORDER BY
    s.order_count DESC;
