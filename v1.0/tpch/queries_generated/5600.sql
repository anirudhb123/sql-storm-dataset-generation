WITH RankedPart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_size,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 1 AND 30
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_size
), SupplierNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        SUM(s.s_acctbal) AS total_acct_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    HAVING 
        total_acct_balance > 1000
), OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS num_items
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, c.c_name
), FinalResults AS (
    SELECT 
        rp.p_name,
        rp.p_mfgr,
        rp.total_available,
        rp.avg_supply_cost,
        sn.n_name AS supplier_nation,
        os.total_sales,
        os.num_items
    FROM 
        RankedPart rp
    JOIN 
        SupplierNation sn ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sn.s_suppkey)
    JOIN 
        OrdersSummary os ON os.total_sales > 5000
)
SELECT 
    p_name,
    p_mfgr,
    total_available,
    avg_supply_cost,
    supplier_nation,
    SUM(total_sales) AS total_sales_summary,
    SUM(num_items) AS total_items_summary
FROM 
    FinalResults
GROUP BY 
    p_name, p_mfgr, total_available, avg_supply_cost, supplier_nation
ORDER BY 
    total_sales_summary DESC, total_items_summary DESC
LIMIT 100;
