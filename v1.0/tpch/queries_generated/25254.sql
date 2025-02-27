WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 10000.00
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000.00
), SupplierDetails AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        hv.order_value
    FROM 
        RankedSuppliers rs
    JOIN 
        HighValueOrders hv ON rs.s_suppkey IN (
            SELECT ps_suppkey 
            FROM partsupp 
            WHERE ps_partkey IN (
                SELECT l.l_partkey 
                FROM lineitem l 
                WHERE l.l_orderkey IN (
                    SELECT o.o_orderkey 
                    FROM orders o 
                    WHERE o.o_orderstatus = 'O'
                )
            )
        )
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    sd.s_acctbal,
    sd.order_value,
    CONCAT('Supplier: ', sd.s_name, ' with balance: ', CAST(sd.s_acctbal AS VARCHAR), 
           ' supplies high value orders totaling: ', CAST(sd.order_value AS VARCHAR)) AS summary
FROM 
    SupplierDetails sd
WHERE 
    sd.rank = 1
ORDER BY 
    sd.order_value DESC;
