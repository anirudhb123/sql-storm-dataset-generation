WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.total_available,
        rp.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY rp.total_available DESC) AS rank
    FROM 
        RankedParts rp
)
SELECT 
    cp.c_name,
    cp.total_orders,
    cp.total_spent,
    tp.p_name,
    tp.total_available,
    tp.avg_supply_cost,
    ss.supplier_count,
    ss.total_account_balance
FROM 
    CustomerOrders cp
JOIN 
    TopParts tp ON tp.rank <= 10
JOIN 
    SupplierStats ss ON ss.supplier_count > 5
ORDER BY 
    cp.total_spent DESC, tp.total_available DESC;
