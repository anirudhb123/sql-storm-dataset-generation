WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS completed_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartDetail AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        ps.ps_availqty,
        p.p_type
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 20
),
FinalReport AS (
    SELECT 
        ss.s_name,
        ss.total_available_qty,
        os.order_count,
        os.total_spent,
        pd.p_name,
        pd.p_size,
        pd.p_retailprice
    FROM 
        SupplierStats ss
    JOIN 
        OrderSummary os ON os.order_count > 5
    LEFT JOIN 
        PartDetail pd ON ss.rank_in_nation = 1 AND pd.p_type LIKE '%Device%'
    WHERE 
        ss.total_cost > 1000
)
SELECT 
    f.s_name,
    COALESCE(f.total_available_qty, 0) AS available_qty,
    COALESCE(f.order_count, 0) AS order_count,
    COALESCE(f.total_spent, 0) AS total_spent,
    f.p_name,
    f.p_size,
    f.p_retailprice
FROM 
    FinalReport f
ORDER BY 
    f.s_name, f.total_spent DESC;
