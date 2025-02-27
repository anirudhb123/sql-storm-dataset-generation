WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
), 
supplier_stats AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
), 
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(sum_ls.total_price_after_discount, 0) AS total_sales,
    COALESCE(sum_ls.total_returned_quantity, 0) AS total_returns,
    r.r_name,
    CASE 
        WHEN r.r_name IS NOT NULL THEN 'Regional Supplier'
        ELSE 'Undefined Region'
    END AS supplier_region,
    (SELECT SUM(c.c_acctbal) 
     FROM customer c 
     WHERE c.c_nationkey IN (SELECT n.n_nationkey 
                             FROM nation n 
                             WHERE n.n_regionkey = 
                             (SELECT r.r_regionkey 
                              FROM region r 
                              WHERE r.r_name = r.r_name)
                             )
     ) AS total_customer_balance
FROM 
    part p
LEFT JOIN 
    supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                   FROM partsupp ps 
                                   WHERE ps.ps_partkey = p.p_partkey 
                                   ORDER BY ps.ps_supplycost ASC 
                                   LIMIT 1)
LEFT JOIN 
    supplier_stats ss ON s.s_suppkey = ss.ps_suppkey
LEFT JOIN 
    lineitem_summary sum_ls ON sum_ls.l_orderkey = (SELECT o.o_orderkey 
                                                     FROM ranked_orders o 
                                                     WHERE o.o_custkey = s.s_nationkey 
                                                     AND o.order_rank = 1
                                                     LIMIT 1)
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice BETWEEN 5.00 AND 100.00
    AND (p.p_comment LIKE '%fragile%' OR p.p_comment IS NULL)
ORDER BY 
    total_sales DESC, 
    supplier_region ASC
FETCH FIRST 50 ROWS ONLY;
