WITH RECURSIVE region_supplier AS (
    SELECT r.r_regionkey, r.r_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE r.r_name LIKE 'S%'
    
    UNION ALL
    
    SELECT r.r_regionkey, r.r_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM region r
    JOIN region_supplier rs ON r.r_regionkey = rs.r_regionkey
    JOIN supplier s ON s.s_suppkey = rs.s_suppkey
    WHERE rs.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
),

supp_part AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, p.p_name, p.p_retailprice
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size IS NOT NULL AND ps.ps_availqty > 0
),

high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND (o.o_totalprice - COALESCE((SELECT SUM(l.l_discount) 
           FROM lineitem l WHERE l.l_orderkey = o.o_orderkey), 0)) > 10000
),

final_selection AS (
    SELECT DISTINCT rs.r_name, rs.s_name, h.o_orderkey, h.o_totalprice
    FROM region_supplier rs
    JOIN high_value_orders h ON h.o_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey % 2 = 0
    )
)

SELECT f.r_name, f.s_name, f.o_orderkey, f.o_totalprice 
FROM final_selection f
WHERE NOT EXISTS (
    SELECT 1 FROM lineitem l
    WHERE l.l_orderkey = f.o_orderkey
    AND (l.l_returnflag = 'R' OR l.l_linestatus = 'O')
)
ORDER BY f.r_name, f.o_totalprice DESC
LIMIT 10;
