WITH Recursive_CTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 20
),
Total_Supplier_Cost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
Order_Summary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_quantity 
            ELSE 0 
        END) AS total_return_qty,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
Supplier_Customer AS (
    SELECT 
        s.s_suppkey,
        c.c_custkey,
        s.s_acctbal,
        c.c_acctbal,
        COALESCE(s.s_acctbal, 0) + COALESCE(c.c_acctbal, 0) AS combined_acctbal
    FROM supplier s
    FULL OUTER JOIN customer c ON s.s_nationkey = c.c_nationkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    SUM(CASE 
        WHEN ts.total_supply_cost IS NULL THEN 0 
        ELSE ts.total_supply_cost 
    END) AS total_supply_value,
    STRING_AGG(DISTINCT CONCAT_WS('|', p.p_name, p.p_brand, p.p_type)) AS part_details,
    SUM(CASE 
        WHEN os.total_line_value > 1000 THEN 1 
        ELSE 0 
    END) AS high_value_orders
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN Total_Supplier_Cost ts ON ts.ps_partkey = (
    SELECT pc.p_partkey 
    FROM Recursive_CTE pc 
    WHERE pc.rank = 1 
    LIMIT 1
)
LEFT JOIN Order_Summary os ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'O'
)
LEFT JOIN Supplier_Customer sc ON sc.combined_acctbal > 1000
GROUP BY r.r_name
HAVING COUNT(DISTINCT ns.n_nationkey) > 5
ORDER BY total_supply_value DESC, r.r_name;
