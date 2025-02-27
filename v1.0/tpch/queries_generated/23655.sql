WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM orders o
    WHERE o.o_orderdate > '1996-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY l.l_orderkey
),
RegionRef AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        n.n_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_name) AS NationRank
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    r.r_name AS region_name,
    COALESCE(l.net_revenue, 0) AS net_revenue,
    COALESCE(ss.total_supply_value, 0) AS supplier_value,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Completed'
        ELSE 'Pending'
    END AS order_status,
    (SELECT COUNT(*) 
     FROM lineitem l2 
     WHERE l2.l_orderkey = o.o_orderkey AND l2.l_linestatus = 'O') AS open_lines,
    String_AGG(DISTINCT CONCAT(n.n_name, '(', r.r_name, ')')) WITHIN GROUP (ORDER BY n.n_name) AS nation_region_concat
FROM RankedOrders o
LEFT JOIN LineItemDetails l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierStats ss ON ss.num_parts > 0
LEFT JOIN RegionRef n ON n.NationRank = 1
GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, r.r_name
HAVING SUM(l.net_revenue) IS NULL AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus <> 'F')
ORDER BY o.o_orderdate DESC, o.o_orderkey;
