WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        MAX(l.l_shipdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        MAX(l.l_shipdate) < CURRENT_DATE - INTERVAL '1 year'
),
FinalReport AS (
    SELECT 
        cs.c_name AS customer_name,
        ss.s_name AS supplier_name,
        ss.s_acctbal AS supplier_balance,
        sps.supplier_count,
        sps.avg_supply_cost,
        hvc.total_spent,
        hvc.total_orders
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        CustomerOrderDetails cs ON hvc.c_custkey = cs.c_custkey
    LEFT JOIN 
        RankedSuppliers ss ON hvc.c_name LIKE CONCAT('%', ss.s_name, '%')
    LEFT JOIN 
        SupplierPartStats sps ON sps.ps_partkey = (SELECT ps.ps_partkey 
                                                    FROM partsupp ps 
                                                    WHERE ps.ps_suppkey = ss.s_suppkey 
                                                    ORDER BY ps.ps_supplycost DESC 
                                                    LIMIT 1)
    WHERE 
        ss.rnk = 1
)
SELECT 
    customer_name,
    supplier_name,
    COALESCE(supplier_balance, 0) AS supplier_balance,
    COALESCE(supplier_count, 0) AS supplier_count,
    COALESCE(avg_supply_cost, 0.00) AS average_supply_cost,
    COALESCE(total_spent, 0.00) AS total_spent,
    COALESCE(total_orders, 0) AS total_orders
FROM 
    FinalReport
WHERE 
    customer_name IS NOT NULL
ORDER BY 
    total_spent DESC,
    supplier_balance DESC;
