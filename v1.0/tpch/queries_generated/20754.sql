WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status_price
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(year, -1, GETDATE())
), 
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 0 
            ELSE s.s_acctbal 
        END AS effective_acctbal,
        RANK() OVER (ORDER BY CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END DESC) AS supplier_rank
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name NOT LIKE 'A%')
)
SELECT 
    COALESCE(p.p_name, 'Unknown Part') AS part_name,
    COALESCE(rs.rank_status_price, 0) AS order_rank,
    cs.order_count,
    fs.s_name,
    fs.effective_acctbal,
    (SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) 
     FROM lineitem l 
     WHERE l.l_orderkey IN (SELECT o.o_orderkey 
                             FROM orders o 
                             WHERE o.o_custkey = cs.c_custkey)) AS total_revenue
FROM part p
LEFT JOIN RankedOrders rs ON rs.o_orderkey = (SELECT TOP 1 o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' ORDER BY o.o_totalprice DESC)
LEFT JOIN CustomerStats cs ON cs.c_custkey = (SELECT TOP 1 c.c_custkey FROM customer c ORDER BY c.c_acctbal DESC)
LEFT JOIN FilteredSuppliers fs ON fs.s_suppkey = (SELECT TOP 1 ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost DESC)
WHERE (p.p_retailprice IS NOT NULL AND p.p_size > 5) OR (p.p_comment IS NULL)
ORDER BY 6 DESC, 4 ASC
LIMIT 50;
