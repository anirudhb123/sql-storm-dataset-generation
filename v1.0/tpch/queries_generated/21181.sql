WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1994-01-01'
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown Balance'
            WHEN s.s_acctbal < 1000 THEN 'Low Balance'
            WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Moderate Balance'
            ELSE 'High Balance'
        END as balance_category
    FROM supplier s
),
coalesced_part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ps.ps_availqty, 0) as available_quantity,
        COALESCE(ps.ps_supplycost, 0) as supply_cost,
        p.p_retailprice - COALESCE(ps.ps_supplycost, 0) as profit_margin
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
complex_filtered_lineitems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_discount * l.l_extendedprice) as total_discounted_value
    FROM lineitem l
    WHERE l.l_shipdate IS NOT NULL
    GROUP BY l.l_orderkey, l.l_partkey
    HAVING SUM(l.l_discount * l.l_extendedprice) > 5000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    sd.s_name,
    cp.p_name,
    cp.profit_margin,
    cpli.total_discounted_value
FROM ranked_orders r
LEFT JOIN complex_filtered_lineitems cpli ON r.o_orderkey = cpli.l_orderkey
JOIN supplier_details sd ON cpli.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN coalesced_part_details cp ON cp.p_partkey = cpli.l_partkey
WHERE 
    r.order_rank <= 10 
    AND (sd.balance_category = 'High Balance' OR sd.balance_category IS NULL)
    AND r.o_totalprice > (SELECT AVG(o.o_totalprice) FROM orders o WHERE o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31')
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;
