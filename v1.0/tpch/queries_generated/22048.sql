WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
        JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        MAX(s.s_acctbal) AS max_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
        LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
        INNER JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(cs.total_sales) AS total_revenue,
    COALESCE(SUM(ss.max_acctbal), 0) AS total_supplier_acctbal,
    COALESCE(SUM(co.total_order_value), 0) AS total_customer_order_value
FROM 
    region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN RankedSales cs ON cs.total_sales > 1000
    LEFT JOIN SupplierStats ss ON ss.part_count > 5
    LEFT JOIN CustomerOrders co ON co.order_count > 10
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY 
    total_revenue DESC NULLS LAST;
