WITH RECURSIVE SalesCTE AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
    UNION ALL
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount))
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN SalesCTE s ON o.o_orderkey > s.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
SupplierData AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
MaxCosts AS (
    SELECT s.s_suppkey, sd.total_cost
    FROM SupplierData sd
    JOIN supplier s ON sd.total_cost = (SELECT MAX(total_cost) FROM SupplierData)
),
CustomerSpending AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
RankedCustomers AS (
    SELECT cs.c_custkey, cs.total_spent,
           RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerSpending cs
)
SELECT rn.rank, c.c_name, rn.total_spent, s.s_name, MAX(sdc.total_cost) AS max_supplier_cost
FROM RankedCustomers rn
JOIN customer c ON rn.c_custkey = c.c_custkey
LEFT JOIN MaxCosts sdc ON sdc.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps 
                                             WHERE ps.ps_availqty > 1000 
                                             ORDER BY ps.ps_supplycost DESC LIMIT 1)
JOIN supplier s ON s.s_suppkey = sdc.s_suppkey
WHERE rn.rank <= 10 AND cn.n_nationkey IS NULL
GROUP BY rn.rank, c.c_name, rn.total_spent, s.s_name
ORDER BY rn.total_spent DESC;
