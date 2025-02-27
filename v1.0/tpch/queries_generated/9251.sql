WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_availqty) AS total_available_quantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT sss.s_suppkey, sss.s_name, sss.s_acctbal, sss.total_available_quantity,
           RANK() OVER (ORDER BY sss.total_available_quantity DESC) AS rnk
    FROM SupplierSummary sss
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, li.l_partkey, li.l_quantity, 
           SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, li.l_partkey, li.l_quantity
),
FinalReport AS (
    SELECT ts.s_suppkey, ts.s_name, ts.total_available_quantity, os.o_orderkey, os.o_orderdate, os.o_totalprice,
           os.l_partkey, os.l_quantity, os.return_count
    FROM TopSuppliers ts
    JOIN OrderSummary os ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = os.l_partkey LIMIT 1)
    WHERE ts.rnk <= 10
)
SELECT fr.s_suppkey, fr.s_name, fr.total_available_quantity, fr.o_orderkey, fr.o_orderdate, fr.o_totalprice,
       fr.l_partkey, fr.l_quantity, fr.return_count
FROM FinalReport fr
ORDER BY fr.total_available_quantity DESC, fr.o_orderdate DESC;
