WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), TopRegions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name 
    ORDER BY 
        nation_count DESC
    LIMIT 5
)
SELECT 
    rs.s_suppkey, 
    rs.s_name, 
    rs.total_cost, 
    hvc.c_custkey, 
    hvc.c_name, 
    hvc.total_spent, 
    tr.r_name 
FROM 
    RankedSuppliers rs
JOIN 
    HighValueCustomers hvc ON rs.total_cost > hvc.total_spent * 0.1
JOIN 
    TopRegions tr ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps 
                                        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
                                        JOIN nation n ON s.s_nationkey = n.n_nationkey 
                                        WHERE n.n_regionkey = tr.r_regionkey)
WHERE 
    rs.rank <= 10
ORDER BY 
    rs.total_cost DESC, hvc.total_spent DESC;
