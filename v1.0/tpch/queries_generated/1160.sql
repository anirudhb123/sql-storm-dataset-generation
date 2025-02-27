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
    WHERE 
        p.p_size > 10 AND 
        s.s_acctbal IS NOT NULL
), OrderAmounts AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
), HighValueOrders AS (
    SELECT 
        oa.o_orderkey, 
        oa.total_amount,
        c.c_nationkey
    FROM 
        OrderAmounts oa
    JOIN 
        customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = oa.o_orderkey)
    WHERE 
        oa.total_amount > 1000
), SupplierDetails AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
        SUM(rs.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON s.s_suppkey = rs.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank = 1
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    s.region_name,
    s.nation_name,
    s.supplier_count,
    s.total_acctbal,
    ho.o_orderkey,
    ho.total_amount
FROM 
    SupplierDetails s
LEFT JOIN 
    HighValueOrders ho ON s.supplier_count > 5
ORDER BY 
    s.supplier_count DESC, s.total_acctbal DESC;
