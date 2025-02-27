WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(li.l_linenumber) AS total_lines,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
),
RegionCustomer AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    WHERE 
        r.r_comment IS NOT NULL AND r.r_comment != ''
    GROUP BY 
        r.r_name
)
SELECT 
    p.p_name,
    s.s_name,
    rh.level,
    CASE 
        WHEN os.last_order_date IS NULL THEN 'No Orders'
        ELSE TO_CHAR(os.last_order_date, 'YYYY-MM-DD')
    END AS last_order,
    rc.customer_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    SupplierHierarchy rh ON s.s_suppkey = rh.s_suppkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = (
        SELECT o.o_orderkey
        FROM orders o
        INNER JOIN lineitem li ON o.o_orderkey = li.l_orderkey
        WHERE li.l_partkey = p.p_partkey
        LIMIT 1
    )
LEFT JOIN 
    RegionCustomer rc ON rc.r_name = (
        SELECT n.r_name
        FROM nation n
        WHERE n.n_nationkey = s.s_nationkey
        LIMIT 1
    )
GROUP BY 
    p.p_name, s.s_name, rh.level, os.last_order_date, rc.customer_count
HAVING 
    SUM(ps.ps_availqty) > 10 OR MAX(ps.ps_supplycost) IS NULL
ORDER BY 
    total_supply_cost DESC, p.p_name;
