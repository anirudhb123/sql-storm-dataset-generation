WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn,
        n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
QualifiedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice < (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size <> p.p_size
    )
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
), 
MaxPricePart AS (
    SELECT 
        qp.p_partkey, 
        MAX(qp.p_retailprice) OVER () AS max_retail_price
    FROM QualifiedParts qp
    WHERE qp.supplier_count > 5
), 
FinalResults AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        STRING_AGG(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN 'Returned Part' ELSE 'Normal Part' END, ', ') AS part_statuses
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN MaxPricePart mpp ON l.l_partkey = mpp.p_partkey
    WHERE o.o_orderstatus IN ('O', 'F') 
      AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY r.r_name, n.n_name
    HAVING COUNT(DISTINCT o.o_orderkey) > (
        SELECT COUNT(*)
        FROM orders o2
        WHERE o2.o_orderdate < '1997-01-01'
        AND o2.o_orderstatus = 'F'
    )
)
SELECT 
    region,
    nation,
    order_count,
    total_revenue,
    part_statuses
FROM FinalResults
ORDER BY total_revenue DESC, region ASC;