
WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        1 AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F'
    UNION ALL
    SELECT 
        s.o_orderkey,
        s.o_orderdate,
        s.o_totalprice,
        c.c_name,
        s.rn + 1
    FROM SalesCTE s 
    JOIN orders o ON s.o_orderkey = o.o_orderkey AND o.o_orderdate < s.o_orderdate
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
NationProductCounts AS (
    SELECT
        n.n_name,
        COUNT(DISTINCT p.p_partkey) AS product_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY n.n_name
)
SELECT 
    COALESCE(ss.s_name, 'Not provided') AS supplier_name,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    np.n_name,
    np.product_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_qty,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales
FROM lineitem l
LEFT JOIN SalesCTE sc ON l.l_orderkey = sc.o_orderkey
LEFT JOIN SupplierStats ss ON l.l_suppkey = ss.s_suppkey
LEFT JOIN NationProductCounts np ON ss.supplier_rank <= 10
GROUP BY 
    ss.s_name, 
    ss.total_avail_qty, 
    ss.avg_supply_cost, 
    np.n_name, 
    np.product_count
HAVING np.product_count > 5
ORDER BY avg_sales DESC, supplier_name;
