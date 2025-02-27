WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
        )
), RecentLineItems AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        li.l_tax,
        li.l_returnflag,
        li.l_linestatus,
        li.l_shipmode,
        LI.l_comment,
        ROW_NUMBER() OVER (PARTITION BY li.l_orderkey ORDER BY li.l_linenumber) AS line_num
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate > CURRENT_DATE - INTERVAL '30 days' 
        AND li.l_discount > 0.05
), SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * rdb.l_quantity) AS total_cost
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN RecentLineItems rdb ON ps.ps_partkey = rdb.l_partkey
    GROUP BY 
        s.s_suppkey
), FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        CASE 
            WHEN COUNT(DISTINCT c.c_custkey) > 5 THEN 'High'
            WHEN COUNT(DISTINCT c.c_custkey) BETWEEN 2 AND 5 THEN 'Medium'
            ELSE 'Low' 
        END AS cust_segment
    FROM 
        nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.o_orderkey,
    r.o_custkey,
    COALESCE(s.total_cost, 0) AS supplier_total_cost,
    fn.cust_segment,
    r.o_orderdate
FROM 
    RankedOrders r
LEFT JOIN SupplierSales s ON r.o_custkey = s.s_suppkey
JOIN FilteredNations fn ON r.o_custkey IN (
    SELECT DISTINCT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey = fn.n_nationkey
)
WHERE 
    r.rn = 1
    AND fn.cust_segment = 'High'
    AND (r.o_orderdate IS NOT NULL 
         AND r.o_orderdate < CURRENT_DATE)
ORDER BY 
    r.o_totalprice DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;

