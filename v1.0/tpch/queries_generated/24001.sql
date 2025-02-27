WITH RECURSIVE nation_suppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(s.s_acctbal) > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
extreme_lineitems AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS extreme_count
    FROM 
        lineitem l
    WHERE 
        l.l_quantity = (SELECT MAX(l2.l_quantity) FROM lineitem l2) OR 
        l.l_quantity = (SELECT MIN(l3.l_quantity) FROM lineitem l3)
    GROUP BY 
        l.l_orderkey
),
partitioned_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    n.n_name,
    coalesce(sum(ps.ps_supplycost), 0) AS total_cost,
    l.l_returnflag,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT CONCAT(l.l_shipmode, ': ', l.l_comment)) AS shipping_details
FROM 
    nation_suppliers n
LEFT JOIN 
    partsupp ps ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey)
RIGHT JOIN 
    extreme_lineitems el ON el.l_orderkey = ps.ps_partkey
LEFT JOIN 
    partitioned_orders o ON o.o_orderkey = el.l_orderkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
WHERE 
    n.total_acctbal IS NOT NULL AND
    l.l_returnflag IN ('R', 'A') OR (l.l_returnflag IS NULL AND l.l_quantity >= 0)
GROUP BY 
    n.n_name, l.l_returnflag
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 AND
    COALESCE(SUM(l.l_discount), 0) >= 0.1 * SUM(l.l_extendedprice) 
ORDER BY 
    n.n_name;
