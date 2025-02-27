WITH CustomerTotal AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY c.c_custkey, c.c_name
), 
TopCustomers AS (
    SELECT c.custkey, 
           c.c_name, 
           c.total_spent,
           ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerTotal c
), 
PartsWithSuppliers AS (
    SELECT p.p_partkey, 
           p.p_name, 
           ps.ps_supplycost,
           s.s_suppkey,
           s.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
), 
EnhancedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           l.l_partkey, 
           l.l_quantity,
           p.p_name,
           ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN PartsWithSuppliers pws ON l.l_partkey = pws.p_partkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
), 
FinalResults AS (
    SELECT tc.c_name,
           eo.o_orderkey,
           eo.o_orderdate,
           eo.p_name,
           eo.l_quantity,
           eo.ps_supplycost,
           (eo.l_quantity * eo.ps_supplycost) AS total_cost
    FROM EnhancedOrders eo
    JOIN TopCustomers tc ON eo.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.custkey)
    WHERE tc.rank <= 10
)
SELECT c.c_name, 
       SUM(fr.total_cost) AS total_spent_by_customer
FROM FinalResults fr
JOIN TopCustomers c ON fr.c_name = c.c_name
GROUP BY c.c_name
ORDER BY total_spent_by_customer DESC;
