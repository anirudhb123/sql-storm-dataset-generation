WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        n.n_regionkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY p.p_partkey
),
HighSalesParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        COALESCE(part_sales.total_sales, 0) AS total_sales
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN PartSales part_sales ON p.p_partkey = part_sales.p_partkey
    WHERE ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp WHERE ps_supplycost > 0)
),
DiverseSales AS (
    SELECT 
        hsp.p_partkey,
        hsp.p_name,
        hsp.total_sales,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM HighSalesParts hsp
    JOIN partsupp ps ON hsp.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY hsp.p_partkey, hsp.p_name, hsp.total_sales
    HAVING COUNT(DISTINCT s.s_suppkey) > 2
)
SELECT 
    d.p_partkey,
    d.p_name,
    d.total_sales,
    rs.s_name AS top_supplier,
    rs.rank_acctbal
FROM DiverseSales d
JOIN RankedSuppliers rs ON d.total_sales > (SELECT AVG(total_sales) FROM DiverseSales WHERE p_partkey <> d.p_partkey)
WHERE EXISTS (
    SELECT 1
    FROM lineitem l
    WHERE l.l_partkey = d.p_partkey AND l.l_returnflag = 'R'
)
ORDER BY d.total_sales DESC, rs.rank_acctbal;
