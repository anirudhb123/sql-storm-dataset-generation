WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
), RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT 
    R.s_name,
    R.nation_name,
    H.p_name,
    H.p_retailprice,
    O.total_revenue,
    R.rank_by_acctbal
FROM 
    RankedSuppliers R
JOIN 
    HighValueParts H ON R.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = H.p_partkey 
        ORDER BY 
            ps.ps_supplycost DESC 
        LIMIT 1
    )
JOIN 
    RecentOrders O ON O.o_custkey = (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        WHERE 
            c.c_nationkey = R.n_nationkey 
        LIMIT 1
    )
ORDER BY 
    R.rank_by_acctbal, O.total_revenue DESC;
