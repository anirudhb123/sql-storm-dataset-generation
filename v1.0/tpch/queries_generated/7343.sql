WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_quantity, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FinalReport AS (
    SELECT 
        hs.s_suppkey, 
        hs.s_name, 
        hvc.c_custkey, 
        hvc.c_name, 
        pd.p_partkey, 
        pd.p_name, 
        pd.supplier_count, 
        ss.total_supply_cost, 
        hvc.total_spent
    FROM 
        HighValueCustomers hvc
    JOIN 
        SupplierStats ss ON ss.total_supply_cost > 5000
    JOIN 
        PartDetails pd ON pd.supplier_count >= 2
    WHERE 
        ss.s_suppkey = pd.supplier_count
)
SELECT * 
FROM FinalReport
ORDER BY total_spent DESC, total_supply_cost ASC
LIMIT 100;
