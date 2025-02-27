WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),

TopSuppliers AS (
    SELECT 
        r.r_regionkey, 
        r.r_name AS region_name, 
        COUNT(DISTINCT rs.s_suppkey) AS top_supplier_count
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = (SELECT n.n_regionkey 
                                               FROM nation n 
                                               WHERE n.n_name = rs.nation_name)
    WHERE 
        rs.rank <= 3
    GROUP BY 
        r.r_regionkey, r.r_name
)

SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(ts.top_supplier_count, 0) AS top_supplier_count
FROM 
    part p
LEFT JOIN 
    TopSuppliers ts ON p.p_partkey IN (SELECT ps.ps_partkey 
                                        FROM partsupp ps 
                                        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
                                        JOIN nation n ON s.s_nationkey = n.n_nationkey 
                                        WHERE n.n_regionkey = ts.r_regionkey)
ORDER BY 
    p.p_partkey;
