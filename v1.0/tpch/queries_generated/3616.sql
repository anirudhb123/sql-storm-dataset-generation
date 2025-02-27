WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY SUM(ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
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
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_type,
    COALESCE(SD.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(SD.total_supply_cost, 0) AS total_supply_cost,
    CALC.total_spent,
    CASE 
        WHEN CALC.total_spent > 10000 THEN 'High Value'
        WHEN CALC.total_spent > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    part p
LEFT OUTER JOIN 
    SupplierDetails SD ON p.p_partkey = SD.ps_partkey
LEFT OUTER JOIN 
    CustomerOrders CALC ON p.p_partkey IN (
        SELECT 
            l.l_partkey
        FROM 
            lineitem l
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE 
            o.o_orderstatus = 'O'
    )
WHERE 
    p.p_retailprice BETWEEN 50 AND 200
  AND 
    EXISTS (
        SELECT 1 
        FROM RankedSuppliers RS 
        WHERE RS.s_suppkey = SD.ps_partkey 
          AND RS.rank = 1
    )
ORDER BY 
    total_supply_cost DESC, 
    p.p_name;
