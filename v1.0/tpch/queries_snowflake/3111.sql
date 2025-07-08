WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice) AS total_order_value
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
NationSupplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS average_supplier_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
EnhancedOrderSummary AS (
    SELECT 
        os.o_orderkey,
        os.total_line_items,
        os.total_order_value,
        ns.n_name,
        ns.supplier_count,
        ns.average_supplier_balance
    FROM 
        OrderSummary os
    JOIN 
        (SELECT 
            l.l_orderkey, 
            COUNT(DISTINCT l.l_suppkey) AS unique_suppliers 
         FROM 
            lineitem l 
         GROUP BY 
            l.l_orderkey) AS unique_suppliers ON os.o_orderkey = unique_suppliers.l_orderkey
    JOIN 
        nation n ON EXISTS (
            SELECT 1 
            FROM supplier s 
            WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX'))
            AND s.s_nationkey = n.n_nationkey
        )
    LEFT JOIN 
        NationSupplier ns ON n.n_name = ns.n_name
)
SELECT 
    eos.o_orderkey,
    eos.total_line_items,
    eos.total_order_value,
    eos.n_name,
    eos.supplier_count,
    eos.average_supplier_balance,
    CASE 
        WHEN eos.total_order_value > 10000 THEN 'High Value'
        WHEN eos.total_order_value BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS order_value_category,
    COALESCE(sums.total_available_qty, 0) AS total_available_qty,
    COALESCE(sums.total_supply_cost, 0) AS total_supply_cost
FROM 
    EnhancedOrderSummary eos
LEFT JOIN 
    SupplierSummary sums ON eos.o_orderkey = sums.s_suppkey 
ORDER BY 
    eos.total_order_value DESC, eos.o_orderkey
LIMIT 100;