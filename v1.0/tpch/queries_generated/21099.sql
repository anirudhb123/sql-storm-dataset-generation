WITH RECURSIVE SupplyDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty IS NOT NULL
),
NationStats AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        SUM(l.l_quantity) AS total_qty,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'P')
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
FinalReport AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        sd.ps_availqty,
        ns.nation_name,
        os.total_price,
        CASE 
            WHEN os.total_qty > 100 THEN 'High Volume'
            WHEN os.total_qty BETWEEN 50 AND 100 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS volume_category,
        COALESCE(ns.total_account_balance, 0) AS nation_balance
    FROM 
        SupplyDetails sd
    JOIN 
        part p ON p.p_partkey = sd.ps_partkey
    LEFT JOIN 
        supplier s ON s.s_suppkey = sd.ps_suppkey
    LEFT JOIN 
        NationStats ns ON s.s_nationkey = ns.s_supplier_count
    LEFT JOIN 
        OrdersSummary os ON os.o_custkey = s.s_nationkey
    WHERE 
        sd.rn = 1
    ORDER BY 
        nation_balance DESC, total_price DESC
)

SELECT 
    DISTINCT fr.p_partkey,
    fr.p_name,
    fr.s_name,
    fr.ps_availqty,
    fr.nation_name,
    fr.total_price,
    fr.volume_category,
    CASE 
        WHEN fr.ps_availqty IS NULL THEN 'No Availability'
        ELSE 'Available'
    END AS availability_status
FROM 
    FinalReport fr
WHERE 
    fr.total_price > (SELECT AVG(total_price) FROM OrdersSummary) 
    OR fr.volume_category = 'High Volume'
HAVING 
    SUM(fr.ps_availqty) > 0
ORDER BY 
    fr.nation_name ASC, fr.total_price DESC
LIMIT 100;
