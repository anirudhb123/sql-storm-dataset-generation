WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) FROM customer c2
        )
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.nation_name,
    rs.s_name,
    rs.part_count,
    hvc.c_name AS high_value_customer,
    hvc.c_acctbal AS customer_acctbal,
    od.lineitem_count,
    od.total_sales
FROM 
    RankedSuppliers rs
JOIN 
    nation r ON r.r_regionkey = (
        SELECT n.r_regionkey FROM nation n WHERE n.n_nationkey = rs.nation_name
    )
JOIN 
    HighValueCustomers hvc ON hvc.o_orderkey = (
        SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_custkey = hvc.c_custkey
    )
JOIN 
    OrderDetails od ON od.o_orderkey = hvc.o_orderkey
WHERE 
    rs.rank_by_acctbal <= 3
ORDER BY 
    r.nation_name, rs.part_count DESC, hvc.c_acctbal DESC;
