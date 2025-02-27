
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM
        supplier s
    WHERE
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
HighValueLineItems AS (
    SELECT
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice * (1 - l.l_discount) AS net_price,
        l.l_shipdate
    FROM
        lineitem l
    WHERE
        l.l_discount IS NOT NULL AND l.l_discount > 0.1
        AND l.l_quantity < 50
),
FilteredOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(hv.net_price) AS total_net_price
    FROM
        orders o
    LEFT JOIN HighValueLineItems hv ON o.o_orderkey = hv.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
    HAVING
        COUNT(hv.l_orderkey) > 5
),
SupplierRegion AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        r.r_name AS region
    FROM
        supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE
        r.r_name IS NOT NULL
)
SELECT
    fr.o_orderdate,
    sr.region,
    COUNT(DISTINCT sr.s_suppkey) AS supplier_count,
    ROUND(AVG(fr.total_net_price), 2) AS avg_order_value,
    STRING_AGG(sr.nation, ', ') AS nations_list,
    CASE 
        WHEN AVG(fr.total_net_price) > 10000 THEN 'High Value'
        WHEN AVG(fr.total_net_price) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS order_value_category
FROM
    FilteredOrders fr
JOIN SupplierRegion sr ON fr.o_orderkey = sr.s_suppkey
WHERE
    fr.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    fr.o_orderdate, sr.region
HAVING
    COUNT(DISTINCT sr.s_suppkey) > 1
ORDER BY
    fr.o_orderdate DESC, avg_order_value DESC;
