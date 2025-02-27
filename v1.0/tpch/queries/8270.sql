WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS RankByBalance
    FROM 
        supplier s
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        ps.ps_availqty,
        ps.ps_supplycost,
        n.n_name AS nation_name
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.RankByBalance <= 3
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        c.c_name,
        o.o_totalprice,
        COUNT(li.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate <= '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey, c.c_name, o.o_totalprice
),
FinalReport AS (
    SELECT 
        cp.p_name,
        cp.p_brand,
        cp.p_type,
        cp.p_size,
        cp.ps_availqty,
        cp.ps_supplycost,
        co.c_name AS customer_name,
        co.o_totalprice,
        co.line_item_count,
        n.n_name AS nation_name
    FROM 
        SupplierParts cp
    JOIN 
        CustomerOrders co ON cp.ps_partkey IN (
            SELECT ps.ps_partkey 
            FROM partsupp ps 
            WHERE ps.ps_suppkey IN (
                SELECT s.s_suppkey 
                FROM RankedSuppliers s
            )
        )
    JOIN 
        nation n ON cp.nation_name = n.n_name
)
SELECT 
    fr.p_name,
    fr.p_brand,
    fr.p_type,
    fr.p_size,
    fr.ps_availqty,
    fr.ps_supplycost,
    fr.customer_name,
    fr.o_totalprice,
    fr.line_item_count,
    fr.nation_name
FROM 
    FinalReport fr
ORDER BY 
    fr.o_totalprice DESC, fr.line_item_count DESC
LIMIT 100;