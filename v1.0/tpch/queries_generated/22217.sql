WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100.00)
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal 
            ELSE 0 
        END AS non_null_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%land%'))
), AggregatedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
), FinalOutput AS (
    SELECT 
        r.r_name AS region,
        np.n_name AS nation_name,
        rp.p_name AS part_name,
        rp.price_rank,
        fs.s_name,
        fo.total_revenue,
        fo.item_count
    FROM 
        RankedParts rp
    LEFT JOIN 
        FilteredSuppliers fs ON fs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey ORDER BY ps.ps_supplycost DESC LIMIT 1)
    JOIN 
        nation np ON np.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = fo.o_orderkey LIMIT 1))
    JOIN 
        region r ON r.r_regionkey = np.n_regionkey
    JOIN 
        AggregatedOrders fo ON rp.p_partkey = fo.o_orderkey
    WHERE 
        (rp.price_rank <= 5 OR rp.p_name LIKE '%X%')
        AND fs.non_null_acctbal > 1000
        AND (fo.total_revenue IS NOT NULL OR fo.item_count > 5)
    ORDER BY 
        fo.total_revenue DESC, rp.price_rank ASC
)
SELECT * FROM FinalOutput
WHERE 
    NOT EXISTS (SELECT 1 FROM lineitem l WHERE l.l_returnflag = 'R')
    OR (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey IN (SELECT fo.o_orderkey FROM FinalOutput fo)) >= ALL (SELECT COUNT(*) FROM orders)
LIMIT 100;
