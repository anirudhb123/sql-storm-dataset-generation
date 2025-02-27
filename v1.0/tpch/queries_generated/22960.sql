WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'O') AND 
        o.o_totalprice IS NOT NULL
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        s.s_name,
        p.p_name,
        p.p_retailprice,
        COALESCE(ps.ps_supplycost, 0) AS ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10 AND 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_comment IS NOT NULL)
),
CustomerAnalysis AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        CUME_DIST() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FinalResult AS (
    SELECT 
        r.o_orderkey, 
        spd.s_name, 
        spd.p_name, 
        spd.ps_availqty, 
        ca.total_spent,
        ca.spend_rank 
    FROM 
        RankedOrders r
    LEFT JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    LEFT JOIN 
        SupplierPartDetails spd ON l.l_partkey = spd.ps_partkey AND spd.supplier_rank = 1
    LEFT JOIN 
        CustomerAnalysis ca ON r.o_orderkey = (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_custkey = ca.c_custkey ORDER BY o2.o_orderdate LIMIT 1)
    WHERE 
        (spd.ps_availqty IS NULL OR spd.ps_availqty > 5) 
        AND (r.o_orderdate >= DATE '2023-01-01' AND r.o_orderdate <= DATE '2023-12-31') 
        AND (ca.order_count > 0 OR ca.total_spent IS NULL)
)
SELECT 
    f.o_orderkey, 
    f.s_name, 
    f.p_name, 
    COALESCE(f.total_spent, 0) AS total_spent, 
    f.spend_rank
FROM 
    FinalResult f
WHERE 
    f.spend_rank < 0.5
ORDER BY 
    f.total_spent DESC, 
    f.o_orderkey
LIMIT 100;
