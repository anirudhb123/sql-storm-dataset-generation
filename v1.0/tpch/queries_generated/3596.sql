WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(day, -30, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.total_supplycost,
    ro.o_orderkey,
    ro.o_totalprice,
    ro.o_orderdate,
    ro.c_name,
    CASE 
        WHEN r.rank <= 5 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_category
FROM 
    RankedSuppliers r
FULL OUTER JOIN 
    RecentOrders ro ON r.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey IN (
                SELECT 
                    p.p_partkey 
                FROM 
                    part p 
                WHERE 
                    p.p_retailprice < 20
            ) 
        ORDER BY 
            ps.ps_supplycost * ps.ps_availqty DESC 
        LIMIT 1
    )
ORDER BY 
    r.s_name, ro.o_orderdate DESC;
