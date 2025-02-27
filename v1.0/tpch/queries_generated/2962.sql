WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
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
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returned
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_retailprice,
    pd.total_returned,
    hs.s_name AS high_acctbal_supplier,
    hvc.c_name AS high_value_customer,
    ROW_NUMBER() OVER (PARTITION BY pd.p_partkey ORDER BY pd.total_returned DESC) AS return_rank
FROM 
    PartDetails pd
LEFT JOIN 
    RankedSuppliers rs ON pd.p_partkey = rs.ps_partkey AND rs.supplier_rank = 1
LEFT JOIN 
    HighValueCustomers hvc ON rs.s_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = pd.p_partkey LIMIT 1)
LEFT JOIN 
    (
        SELECT 
            ps.ps_partkey, 
            SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
        FROM 
            partsupp ps
        GROUP BY 
            ps.ps_partkey
    ) AS ps_total ON pd.p_partkey = ps_total.ps_partkey
WHERE 
    pd.total_returned > 0
ORDER BY 
    pd.total_returned DESC, pd.p_partkey;
