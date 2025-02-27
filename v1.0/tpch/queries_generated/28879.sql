WITH SupplierDetails AS (
    SELECT s.s_name, s.s_address, n.n_name AS nation_name, r.r_name AS region_name,
           s.s_acctbal, s.s_comment, 
           STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), ', ') AS supplied_parts
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, n.n_name, r.r_name, s.s_acctbal, s.s_comment
),
OrderSummary AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS total_lineitems, SUM(l.l_extendedprice) AS total_price,
           STRING_AGG(DISTINCT l.l_shipmode, ', ') AS ship_modes,
           STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers_used
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY o.o_orderkey
)
SELECT sd.s_name, sd.nation_name, sd.region_name, sd.s_acctbal, sd.supplied_parts,
       os.total_lineitems, os.total_price, os.ship_modes, os.suppliers_used
FROM SupplierDetails sd
JOIN OrderSummary os ON sd.s_name = ANY(STRING_TO_ARRAY(os.suppliers_used, ', '));
