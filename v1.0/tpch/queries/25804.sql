WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    FROM RankedSuppliers s
    JOIN nation n ON s.s_suppkey = s.s_suppkey
    WHERE rn = 1
),
FrequentParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 500
),
PopularParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    FROM part p
    JOIN FrequentParts f ON p.p_partkey = f.ps_partkey
    WHERE p.p_retailprice < 50.00
),
FinalBenchmark AS (
    SELECT t.s_name AS supplier_name, 
           p.p_name AS part_name, 
           p.p_retailprice, 
           t.n_name AS nation_name
    FROM TopSuppliers t
    JOIN PopularParts p ON t.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey
    )
)
SELECT supplier_name, part_name, p_retailprice, nation_name
FROM FinalBenchmark
ORDER BY nation_name, supplier_name;
