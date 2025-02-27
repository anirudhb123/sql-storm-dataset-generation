WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 50 AND
        (p.p_comment IS NULL OR p.p_comment NOT LIKE '%defective%')
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > (CURRENT_DATE - INTERVAL '1YEAR') AND
        (l.l_discount BETWEEN 0.05 AND 0.1 OR l.l_returnflag = 'R')
    GROUP BY 
        o.o_orderkey,
        o.o_custkey
),
NationsWithHighBalance AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        ss.total_suppliers,
        ss.total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    WHERE 
        ss.total_account_balance IS NOT NULL AND
        ss.total_account_balance > (SELECT AVG(total_account_balance) FROM SupplierStats)
),
Result AS (
    SELECT 
        np.n_name AS nation_name,
        rp.p_name AS part_name,
        rp.p_retailprice AS part_price,
        ho.order_value AS high_value_order
    FROM 
        RankedParts rp
    JOIN 
        HighValueOrders ho ON rp.rank <= 3
    JOIN 
        NationsWithHighBalance np ON ho.o_orderkey % 5 = np.n_nationkey % 5
    WHERE 
        ho.order_value IS NOT NULL 
        AND (rp.p_retailprice > 100 OR rp.p_name LIKE '%Special%')
        AND (np.total_suppliers IS NOT NULL OR np.total_suppliers > 10)
)
SELECT 
    nation_name,
    part_name,
    SUM(part_price) AS total_part_price,
    COUNT(high_value_order) AS number_of_high_value_orders
FROM 
    Result
GROUP BY 
    nation_name, 
    part_name
HAVING 
    SUM(part_price) > 300
ORDER BY 
    total_part_price DESC NULLS LAST;
