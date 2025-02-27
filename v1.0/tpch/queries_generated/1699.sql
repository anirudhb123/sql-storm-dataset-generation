WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank_by_price
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_price,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
),
FinalAnalysis AS (
    SELECT 
        rn.r_name,
        pd.p_name,
        pd.p_size,
        SUM(pd.total_supply_cost) AS aggregate_cost,
        COUNT(DISTINCT co.c_custkey) AS customer_count,
        AVG(co.total_price) AS avg_order_value
    FROM 
        PartSupplierDetails pd
    LEFT JOIN 
        part p ON pd.ps_partkey = p.p_partkey
    LEFT JOIN 
        nation n ON p.p_size = n.n_nationkey
    LEFT JOIN 
        region rn ON n.n_regionkey = rn.r_regionkey
    LEFT JOIN 
        CustomerOrderDetails co ON co.total_price > 1000
    GROUP BY 
        rn.r_name, pd.p_name, pd.p_size
)
SELECT 
    fa.r_name,
    fa.p_name,
    fa.p_size,
    fa.aggregate_cost,
    fa.customer_count,
    fa.avg_order_value,
    CASE 
        WHEN fa.customer_count > 50 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    FinalAnalysis fa
WHERE 
    fa.aggregate_cost IS NOT NULL
ORDER BY 
    fa.aggregate_cost DESC, fa.customer_count ASC;
