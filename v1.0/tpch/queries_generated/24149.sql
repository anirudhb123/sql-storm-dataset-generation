WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate > DATE '2022-01-01'
),
HighValueSuppliers AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CustomerNation AS (
    SELECT 
        c.c_custkey, 
        n.n_name,
        COUNT(o.o_orderkey) as order_count
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_name
    HAVING 
        COUNT(o.o_orderkey) > 10 OR n.n_name IS NULL
),
FinalResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COALESCE(MAX(cnt.order_count), 0) AS customer_order_count,
        CASE 
            WHEN COUNT(DISTINCT s.s_suppkey) > 3 THEN 'Multiple Suppliers'
            ELSE 'Single Supplier'
        END AS supplier_status
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        CustomerNation cnt ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = cnt.n_name)
    WHERE 
        l.l_shipdate BETWEEN DATE '2021-01-01' AND DATE '2023-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        revenue > (SELECT AVG(o.o_totalprice) FROM RankedOrders r WHERE r.rn = 1)
)
SELECT 
    f.p_partkey, 
    f.p_name, 
    f.revenue,
    f.customer_order_count,
    f.supplier_status,
    CASE 
        WHEN f.revenue IS NULL THEN 'No Revenue' 
        ELSE 'Revenue Exists' 
    END AS revenue_status
FROM 
    FinalResults f
ORDER BY 
    f.revenue DESC, 
    f.customer_order_count DESC;
