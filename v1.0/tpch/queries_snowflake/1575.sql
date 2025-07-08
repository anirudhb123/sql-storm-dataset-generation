
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_revenue_returned,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(sd.total_supply_cost) AS avg_supply_cost,
    LISTAGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN RankedOrders ro ON o.o_orderkey = ro.o_orderkey
LEFT JOIN (SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) as total_supply_cost 
            FROM supplier s 
            LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
            GROUP BY s.s_suppkey) sd ON l.l_suppkey = sd.s_suppkey
LEFT JOIN part p ON l.l_partkey = p.p_partkey
WHERE ro.rn <= 10
GROUP BY r.r_name, sd.total_supply_cost
ORDER BY total_revenue DESC, r.r_name;
