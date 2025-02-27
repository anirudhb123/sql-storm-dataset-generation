WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
), HighVolumeOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_quantity) > 1000
), SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        ps.ps_availqty,
        p.p_retailprice,
        COALESCE(MAX(s.s_acctbal), 0) AS max_supplier_acctbal
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, p.p_name, ps.ps_availqty, p.p_retailprice
), OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_count,
        COUNT(DISTINCT c.c_custkey) AS unique_customers_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.n_name AS nation_name,
    COALESCE(SUM(hv.total_quantity), 0) AS total_ordered_quantity,
    COUNT(DISTINCT r.s_suppkey) AS distinct_suppliers,
    AVG(sp.max_supplier_acctbal) AS avg_max_supplier_acctbal,
    OA.unique_parts_count,
    OA.unique_customers_count,
    OA.net_revenue
FROM 
    nation r
LEFT JOIN 
    RankedSuppliers rs ON r.n_nationkey = rs.s_nationkey AND rs.supplier_rank <= 5
LEFT JOIN 
    HighVolumeOrders hv ON hv.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o
        WHERE 
            o.o_orderstatus = 'O'
    )
LEFT JOIN 
    SupplierPartDetails sp ON sp.ps_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_returnflag = 'R'
    )
LEFT JOIN 
    OrderAnalysis OA ON OA.o_orderkey = hv.o_orderkey
GROUP BY 
    r.n_name
ORDER BY 
    total_ordered_quantity DESC, 
    avg_max_supplier_acctbal ASC
FETCH FIRST 10 ROWS ONLY;
