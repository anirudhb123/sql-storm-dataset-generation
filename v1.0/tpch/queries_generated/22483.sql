WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_shippriority ORDER BY o.o_orderdate) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < CURRENT_DATE)
), order_details AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        COUNT(DISTINCT lo.l_partkey) AS unique_parts,
        SUM(lo.l_quantity) AS total_quantity,
        MAX(lo.l_shipdate) AS last_ship_date,
        MIN(lo.l_shipdate) AS first_ship_date
    FROM 
        lineitem lo 
    JOIN 
        ranked_orders ro ON lo.l_orderkey = ro.o_orderkey
    GROUP BY 
        lo.l_orderkey
), supplier_info AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        MAX(s.s_acctbal) AS max_acct_balance
    FROM 
        partsupp ps 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
)
SELECT 
    d.o_orderkey,
    d.revenue,
    d.unique_parts,
    d.total_quantity,
    SI.total_supply_cost,
    SI.max_acct_balance,
    CASE 
        WHEN d.last_ship_date IS NULL THEN 'No shipping info' 
        ELSE CONCAT('Shipped last on ', TO_CHAR(d.last_ship_date, 'YYYY-MM-DD')) 
    END AS shipping_status,
    NULLIF(SUBSTRING(b.r_name, 1, 3), '') AS region_code
FROM 
    order_details d
LEFT JOIN 
    (SELECT n.n_nationkey, r.r_name FROM nation n JOIN region r ON n.n_regionkey = r.r_regionkey) b ON d.o_orderkey % 5 = 0
JOIN 
    supplier_info SI ON d.o_orderkey % 10 = 0 
WHERE 
    d.revenue > (SELECT AVG(revenue) FROM order_details) 
    AND SI.total_supply_cost IS NOT NULL
ORDER BY 
    d.revenue DESC 
FETCH FIRST 10 ROWS ONLY;
