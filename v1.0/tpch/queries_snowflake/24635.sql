WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_linenumber) AS item_count,
        o.o_orderstatus,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS value_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING COUNT(l.l_linenumber) > 1
),
ExpensiveOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_value,
        od.item_count,
        CASE 
            WHEN od.o_orderstatus = 'O' THEN 'Open'
            WHEN od.o_orderstatus = 'F' THEN 'Finished'
            ELSE 'Other'
        END AS order_status_readable
    FROM OrderDetails od
    WHERE od.total_value > (SELECT AVG(total_value) FROM OrderDetails)
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(rs.total_supply_cost, 0) AS supplier_cost,
    eo.total_value AS order_total_value,
    eo.order_status_readable,
    (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)) AS customer_count,
    CASE 
        WHEN eo.item_count > 5 THEN 'High Value Order'
        ELSE 'Standard Order'
    END AS order_category
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
LEFT JOIN ExpensiveOrders eo ON eo.o_orderkey = ps.ps_partkey
JOIN region r ON r.r_regionkey = (SELECT DISTINCT n.n_regionkey FROM nation n WHERE n.n_nationkey = ps.ps_suppkey)
WHERE rs.rank <= 3 
  AND (eo.total_value IS NOT NULL OR ps.ps_availqty IS NULL)
ORDER BY supplier_cost DESC, p.p_name
LIMIT 100;
