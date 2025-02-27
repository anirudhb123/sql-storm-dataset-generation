WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        s.s_name
    FROM 
        OrderSummary os
    LEFT JOIN 
        RankedSuppliers s ON s.s_suppkey = (
            SELECT 
                ps.ps_suppkey
            FROM 
                partsupp ps
            JOIN 
                part p ON ps.ps_partkey = p.p_partkey
            WHERE 
                EXISTS (
                    SELECT 1 
                    FROM lineitem l 
                    WHERE l.l_orderkey = os.o_orderkey AND l.l_partkey = p.p_partkey
                )
            ORDER BY 
                ps.ps_supplycost ASC
            LIMIT 1
        )
    WHERE 
        os.total_revenue > (
            SELECT AVG(total_revenue) 
            FROM OrderSummary 
            WHERE total_revenue IS NOT NULL
        )
)
SELECT 
    h.o_orderkey,
    h.total_revenue,
    COALESCE(h.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN h.total_revenue IS NULL THEN 'No Revenue'
        WHEN h.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Moderate Revenue'
    END AS revenue_category,
    DENSE_RANK() OVER (ORDER BY h.total_revenue DESC) AS revenue_rank
FROM 
    HighValueOrders h
FULL OUTER JOIN 
    nation n ON (n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = h.o_orderkey % 100)) OR (n.n_name IS NULL)
ORDER BY 
    h.total_revenue DESC NULLS LAST;
