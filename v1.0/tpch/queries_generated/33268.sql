WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) > 10000
), CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    s.s_name,
    COALESCE(cs.total_orders, 0) AS customer_orders,
    COALESCE(sd.total_supply_cost, 0) AS supplier_costs,
    (CASE 
        WHEN cs.total_orders IS NULL THEN 'No Orders'
        ELSE 'Order Placed'
    END) AS order_status,
    DENSE_RANK() OVER (ORDER BY SUM(sd.total_supply_cost) DESC) AS supplier_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN CustomerSales cs ON cs.total_orders > 1000
GROUP BY r.r_name, s.s_name, cs.total_orders
HAVING SUM(sd.total_supply_cost) IS NOT NULL
ORDER BY supplier_rank, customer_orders DESC
LIMIT 100;
