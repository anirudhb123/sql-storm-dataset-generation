WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
FilteredOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_price,
        od.o_orderdate
    FROM OrderDetails od
    WHERE od.order_rank = 1 AND od.total_price > 1000
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ss.total_supply_cost,
        ss.num_parts,
        r.r_name
    FROM part p
    LEFT JOIN SupplierSummary ss ON p.p_partkey = ss.s_suppkey
    LEFT JOIN nation n ON n.n_nationkey = ss.s_suppkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_name,
    COALESCE(ft.total_price, 0) AS last_order_price,
    COALESCE(AVG(p.p_retailprice), 0) AS avg_retail_price,
    CASE 
        WHEN COUNT(ft.o_orderkey) > 0 THEN 'Ordered'
        ELSE 'Not Ordered' 
    END AS order_status
FROM part p
LEFT JOIN FilteredOrders ft ON p.p_partkey = ft.o_orderkey
GROUP BY p.p_name
HAVING COUNT(DISTINCT ft.o_orderkey) < 5
ORDER BY last_order_price DESC, p.p_name;
