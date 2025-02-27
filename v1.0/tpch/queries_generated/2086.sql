WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TotalSales AS (
    SELECT 
        SUM(total_sale) AS grand_total_sale 
    FROM 
        RankedOrders
)
SELECT 
    n.n_name,
    COALESCE(SUM(sd.total_supply_value), 0) AS total_supplier_value,
    COALESCE(ts.grand_total_sale, 0) AS grand_total_sale,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS order_rank
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN 
    orders o ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
                                (SELECT p.p_partkey FROM part p WHERE p.p_brand LIKE 'Brand%'))
LEFT JOIN 
    TotalSales ts ON 1=1
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name, ts.grand_total_sale
ORDER BY 
    total_supplier_value DESC, n.n_name ASC;
