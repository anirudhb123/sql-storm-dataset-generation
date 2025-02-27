WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 100000
),
PartDetail AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
        AVG(l.l_extendedprice) AS avg_extended_price
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
SupplierPartDetail AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(s.s_acctbal) AS avg_supplier_account_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
FinalBenchmark AS (
    SELECT 
        p.p_name,
        pd.total_quantity_sold,
        pd.avg_extended_price,
        (SELECT COUNT(DISTINCT n.n_name) FROM nation n WHERE n.n_nationkey = c.c_nationkey) AS unique_nations_count,
        s.total_available,
        rs.total_supply_cost,
        c.c_name AS high_value_customer_name,
        c.total_spent
    FROM 
        PartDetail pd
    LEFT JOIN 
        SupplierPartDetail s ON pd.p_partkey = s.ps_partkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.s_suppkey IN (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey = pd.p_partkey
        )
    LEFT JOIN 
        HighValueCustomers c ON c.total_spent IS NOT NULL
    WHERE 
        pd.total_quantity_sold > 0
    ORDER BY 
        rs.total_supply_cost DESC, c.total_spent DESC
)
SELECT 
    *
FROM 
    FinalBenchmark
WHERE 
    avg_extended_price > 50.00
    AND unique_nations_count > 2;
