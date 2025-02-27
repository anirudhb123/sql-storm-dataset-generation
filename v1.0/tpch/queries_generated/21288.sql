WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
CustOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
PartSupply AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
BizarreCase AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(NULLIF(CAST(NULL AS DECIMAL(12,2)), 0), p.p_retailprice) AS adjusted_price,
        EXISTS (
            SELECT 1 
            FROM lineitem l 
            WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R'
        ) AS returns_flag
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 50 
        AND (p.p_type LIKE '%wood%' OR p.p_type LIKE '%metal%')
), 
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_brand
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
FinalResults AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS average_acctbal,
        SUM(CASE WHEN c.total_orders > 10 THEN c.total_spent ELSE 0 END) AS high_spender_total
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        CustOrders c ON c.c_custkey IN (SELECT c1.c_custkey FROM customer c1 WHERE c1.c_nationkey = n.n_nationkey)
    LEFT JOIN 
        SupplierPartDetails sp ON sp.s_suppkey = rs.s_suppkey
    WHERE 
        rs.rnk = 1
    GROUP BY 
        r.r_name
)
SELECT 
    f.r_name,
    f.supplier_count,
    f.average_acctbal,
    f.high_spender_total,
    (f.high_spender_total - COALESCE((SELECT SUM(ps.ps_supplycost) FROM PartSupply ps), 0)) AS net_value
FROM 
    FinalResults f
WHERE 
    f.supplier_count > 5
    AND f.average_acctbal > (SELECT AVG(s.s_acctbal) FROM supplier s WHERE s.s_acctbal IS NOT NULL)
ORDER BY 
    f.r_name DESC;
