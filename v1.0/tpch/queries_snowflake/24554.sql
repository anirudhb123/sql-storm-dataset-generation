WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_retailprice, 
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
SupplierInfo AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT co.c_custkey, 
           co.c_name, 
           co.order_count, 
           co.total_spent,
           RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
    FROM CustomerOrders co
    WHERE co.total_spent IS NOT NULL
),
FilteredSuppliers AS (
    SELECT si.*, 
           CASE 
               WHEN si.total_supply_cost IS NULL THEN 'Unknown'
               WHEN si.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierInfo) THEN 'Above Average'
               ELSE 'Below Average'
           END AS cost_category
    FROM SupplierInfo si
    WHERE si.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%A%' OR n.n_name LIKE '%E%')
)
SELECT p.p_name, 
       p.p_brand,
       p.p_retailprice,
       rc.c_name AS top_customer,
       rc.total_spent AS customer_spending,
       fs.cost_category
FROM RankedParts p
JOIN FilteredSuppliers fs ON fs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost DESC LIMIT 1)
JOIN RankedCustomers rc ON rc.order_count > (SELECT AVG(order_count) FROM RankedCustomers)
WHERE p.price_rank <= 5 AND (fs.total_supply_cost IS NOT NULL OR fs.s_name IS NULL)
ORDER BY p.p_retailprice DESC, rc.total_spent ASC;
