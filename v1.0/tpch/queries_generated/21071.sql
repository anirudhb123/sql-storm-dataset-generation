WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),

OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_parts,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),

CustomerNation AS (
    SELECT 
        DISTINCT c.c_custkey,
        n.n_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance' 
            WHEN c.c_acctbal < 0 THEN 'Negative Balance' 
            ELSE 'Positive Balance' 
        END AS balance_status
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),

FinalResults AS (
    SELECT 
        cn.n_name AS nation_name,
        COUNT(DISTINCT os.o_orderkey) AS orders_count,
        SUM(os.total_revenue) AS total_revenue,
        COUNT(DISTINCT rs.s_suppkey) AS prominent_suppliers_count,
        SUM(CASE WHEN rs.supplier_rank = 1 THEN rs.s_acctbal ELSE 0 END) AS top_supplier_balance
    FROM 
        OrderSummary os
    JOIN 
        CustomerNation cn ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cn.c_custkey)
    LEFT JOIN 
        RankedSuppliers rs ON rs.s_suppkey IN (SELECT DISTINCT l.l_suppkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
    GROUP BY 
        cn.n_name
)

SELECT 
    fr.nation_name,
    fr.orders_count,
    fr.total_revenue,
    COALESCE(fr.prominent_suppliers_count, 0) AS prominent_suppliers_count,
    COALESCE(fr.top_supplier_balance, 0) AS top_supplier_balance,
    CASE 
        WHEN fr.total_revenue IS NULL THEN 'No Revenue' 
        WHEN fr.total_revenue > 100000 THEN 'High Revenue' 
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM 
    FinalResults fr
ORDER BY 
    fr.total_revenue DESC, fr.nation_name;
