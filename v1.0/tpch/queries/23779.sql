
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p 
    WHERE 
        p.p_retailprice > (
            SELECT AVG(ps.ps_supplycost) 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey
        )
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(s.s_acctbal) OVER (PARTITION BY n.n_nationkey) AS total_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND
        (s.s_comment LIKE '%urgent%' OR s.s_comment IS NULL)
), OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_value_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
), FinalReport AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        sd.s_name AS supplier_name,
        os.total_order_value,
        COALESCE(sd.total_acctbal, 0) AS total_account_balance,
        CASE 
            WHEN os.total_order_value > 1000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS value_category
    FROM 
        RankedParts rp
    LEFT JOIN 
        SupplierDetails sd ON rp.p_partkey = ANY (
            SELECT ps.ps_partkey 
            FROM partsupp ps 
            WHERE ps.ps_supplycost > (
                SELECT AVG(ps2.ps_supplycost) 
                FROM partsupp ps2 
                WHERE ps2.ps_partkey = rp.p_partkey
            )
        )
    LEFT JOIN 
        OrderSummary os ON os.o_orderkey = (
            SELECT o.o_orderkey 
            FROM orders o 
            WHERE o.o_custkey IN (
                SELECT c.c_custkey 
                FROM customer c 
                WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = sd.nation_name)
            )
            AND o.o_orderstatus = 'O'
            ORDER BY o.o_orderdate DESC
            LIMIT 1
        )
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    p.supplier_name, 
    p.total_order_value, 
    p.value_category
FROM 
    FinalReport p
WHERE 
    p.p_retailprice IS NOT NULL
ORDER BY 
    p.value_category DESC, p.p_retailprice ASC;
