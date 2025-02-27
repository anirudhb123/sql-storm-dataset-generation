WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
RankedSuppliers AS (
    SELECT si.*, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY si.total_supply_cost DESC) AS rank
    FROM SupplierInfo si
    JOIN nation n ON si.s_nationkey = n.n_nationkey
),
TopCustomers AS (
    SELECT co.*, 
           RANK() OVER (ORDER BY co.total_order_value DESC) AS customer_rank
    FROM CustomerOrders co
),
FinalResults AS (
    SELECT r.r_name AS region, s.s_name AS supplier_name, c.c_name AS customer_name,
           co.total_order_value, ss.total_supply_cost
    FROM RankedSuppliers s
    FULL OUTER JOIN TopCustomers co ON s.rank = 1 AND co.customer_rank <= 10
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.total_supply_cost IS NOT NULL OR co.total_order_value IS NOT NULL
)
SELECT region, supplier_name, customer_name, 
       COALESCE(total_order_value, 0) AS total_order_value, 
       COALESCE(total_supply_cost, 0) AS total_supply_cost
FROM FinalResults
ORDER BY region, supplier_name, customer_name;
