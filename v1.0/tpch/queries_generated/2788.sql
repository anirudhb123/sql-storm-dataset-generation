WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) as price_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name as nation_name
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT
    p.p_partkey,
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(sd.nation_name, 'Unknown') AS supplier_nation,
    so.max_order_total
FROM
    part p
LEFT JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN (
    SELECT 
        o_custkey,
        MAX(o_totalprice) AS max_order_total
    FROM 
        orders
    GROUP BY 
        o_custkey
) so ON s.s_suppkey = so.o_custkey
WHERE
    l.l_returnflag = 'N' AND
    l.l_shipdate BETWEEN '2023-06-01' AND '2023-12-31'
GROUP BY
    p.p_partkey, p.p_name, sd.nation_name, so.max_order_total
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, avg_extended_price ASC;
