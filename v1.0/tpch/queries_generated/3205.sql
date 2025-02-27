WITH NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance,
        AVG(s.s_acctbal) AS average_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
PriceAnalysis AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(ps.ps_supplycost) AS average_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
ItemDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        COALESCE(pa.total_cost, 0) AS total_supply_cost,
        COALESCE(pa.average_cost, 0) AS average_supply_cost
    FROM 
        part p
    LEFT JOIN 
        PriceAnalysis pa ON p.p_partkey = pa.ps_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    d.n_name,
    d.supplier_count,
    d.total_account_balance,
    d.average_account_balance,
    i.p_name,
    i.p_retailprice,
    i.total_supply_cost,
    i.average_supply_cost,
    o.total_revenue,
    CASE 
        WHEN o.total_revenue IS NOT NULL THEN 'Revenue Generated'
        ELSE 'No Revenue'
    END AS revenue_status
FROM 
    NationSummary d
LEFT JOIN 
    customer c ON d.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = c.c_nationkey)
LEFT JOIN 
    ItemDetails i ON EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = i.p_partkey)
LEFT JOIN 
    OrderSummary o ON o.o_custkey = c.c_custkey
WHERE 
    d.total_account_balance > (SELECT AVG(total_account_balance) FROM NationSummary)
ORDER BY 
    d.n_name, o.total_revenue DESC;
