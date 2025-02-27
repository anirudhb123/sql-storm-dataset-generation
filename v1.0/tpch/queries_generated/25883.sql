WITH StringAggregations AS (
    SELECT 
        p.p_partkey,
        STRING_AGG(DISTINCT SUBSTRING(p.p_name, 1, 20), ', ') AS short_names,
        STRING_AGG(DISTINCT p.p_comment, '; ') AS comments
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
    GROUP BY 
        p.p_partkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    sa.p_partkey,
    sa.short_names,
    sa.comments,
    sd.supplier_info,
    cd.total_spent,
    cd.total_orders
FROM 
    StringAggregations sa
JOIN 
    partsupp ps ON sa.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerOrders cd ON cd.total_spent > 1000
WHERE 
    EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = sa.p_partkey 
        AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    )
ORDER BY 
    sa.p_partkey, cd.total_spent DESC;
