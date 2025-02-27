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
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rn <= 3
),
PartSupply AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    p.p_name,
    ps.total_available,
    os.order_status,
    os.total_order_value,
    rs.s_name,
    rs.s_acctbal
FROM 
    PartSupply ps
LEFT JOIN 
    TopSuppliers rs ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = rs.s_suppkey)
LEFT JOIN 
    OrderDetails os ON os.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_partkey = ps.p_partkey)
WHERE 
    (rs.s_acctbal > 1000 OR rs.s_name IS NULL)
    AND ps.total_available IS NOT NULL
ORDER BY 
    ps.total_available DESC, 
    os.total_order_value DESC;
