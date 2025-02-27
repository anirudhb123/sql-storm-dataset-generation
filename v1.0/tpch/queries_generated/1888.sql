WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2022-01-01' AND l.l_shipdate <= DATE '2022-12-31'
    GROUP BY 
        l.l_partkey
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_availqty,
    ps.avg_supplycost,
    ts.total_sales,
    cs.c_name AS top_customer,
    cs.o_orderdate
FROM 
    PartStatistics ps
LEFT JOIN 
    TotalSales ts ON ps.p_partkey = ts.l_partkey
LEFT JOIN 
    CustomerOrders cs ON cs.order_rank = 1
JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (SELECT ps_suppkey 
                                            FROM partsupp 
                                            WHERE ps_partkey = ps.p_partkey 
                                            ORDER BY ps_supplycost ASC 
                                            LIMIT 1)
WHERE 
    ps.total_availqty IS NOT NULL
    AND ts.total_sales IS NOT NULL
ORDER BY 
    ps.avg_supplycost DESC, 
    total_sales ASC;
