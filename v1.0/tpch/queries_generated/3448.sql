WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        order_value > 10000
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acct_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    ns.supplier_count,
    ns.total_acct_balance,
    ROUND(SUM(o.order_value), 2) AS total_order_value,
    AVG(si.total_supply_cost) AS avg_supply_cost_per_supplier,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY ns.supplier_count DESC) AS rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationSummary ns ON n.n_name = ns.n_name
LEFT JOIN 
    HighValueOrders o ON n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_acctbal > 0)
LEFT JOIN 
    SupplierInfo si ON si.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 500))
GROUP BY 
    r.r_name, n.n_name, ns.supplier_count, ns.total_acct_balance
ORDER BY 
    r.r_name, rank;
