WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        CASE 
            WHEN p.p_size > 10 THEN 'Large' 
            ELSE 'Small' 
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND 
        p.p_mfgr NOT LIKE '%obsolete%'
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_orderkey) AS total_lineitems
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
CustomerHistory AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent, 
        COUNT(DISTINCT o.o_orderkey) AS num_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        fs.p_partkey, 
        fs.size_category, 
        rs.s_name, 
        rs.s_acctbal
    FROM 
        FilteredParts fs
    JOIN 
        RankedSuppliers rs ON fs.p_partkey = (SELECT ps.ps_partkey 
                                             FROM partsupp ps 
                                             WHERE ps.ps_suppkey = rs.s_suppkey 
                                             ORDER BY ps.ps_supplycost ASC 
                                             LIMIT 1)
    WHERE 
        rs.rn = 1
)
SELECT 
    ch.c_name, 
    ch.total_spent, 
    COALESCE(ts.size_category, 'Undefined') AS part_size_category, 
    COALESCE(ts.s_name, 'No Supplier') AS top_supplier
FROM 
    CustomerHistory ch
LEFT JOIN 
    TopSuppliers ts ON ch.num_orders > 10 
WHERE 
    ch.total_spent > (SELECT AVG(total_spent) FROM CustomerHistory)
ORDER BY 
    ch.total_spent DESC
LIMIT 100;
