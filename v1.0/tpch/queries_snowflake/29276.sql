
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE rs.rank <= 5
), 
SupplierComments AS (
    SELECT t.s_name, t.s_acctbal, LISTAGG(CONCAT(s.s_comment, ' - from ', s.s_name), '; ') WITHIN GROUP (ORDER BY s.s_comment) AS all_comments
    FROM TopSuppliers t
    JOIN supplier s ON t.s_suppkey = s.s_suppkey
    GROUP BY t.s_name, t.s_acctbal
) 
SELECT p.p_name, p.p_retailprice, sc.s_name, sc.all_comments
FROM part p
JOIN TopSuppliers ts ON p.p_partkey = ts.s_suppkey
JOIN SupplierComments sc ON ts.s_name = sc.s_name
WHERE p.p_retailprice > 100.00
ORDER BY p.p_retailprice DESC, sc.s_acctbal DESC;
