WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank,
        p.p_name,
        p.p_brand,
        p.p_retailprice
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
), CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
), SupplierDetails AS (
    SELECT
        rs.s_name,
        rs.p_name,
        CASE 
            WHEN rs.rank = 1 THEN 'Top Supplier'
            WHEN rs.rank IS NULL THEN 'No Supplier'
            ELSE 'Other Supplier'
        END AS supplier_status,
        cd.total_spent
    FROM
        RankedSuppliers rs
    LEFT JOIN
        CustomerOrders cd ON rs.s_suppkey = cd.c_custkey
)
SELECT 
    sd.s_name,
    sd.p_name,
    sd.supplier_status,
    COALESCE(sd.total_spent, 0) AS total_spent,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_suppkey = rs.s_suppkey AND l.l_shipdate > CURRENT_DATE - INTERVAL '1 year') AS recent_shipments,
    (CASE 
         WHEN sd.total_spent IS NULL THEN 'No Orders'
         WHEN sd.total_spent > 10000 THEN 'High Value Customer'
         ELSE 'Standard Customer'
     END) AS customer_value
FROM 
    SupplierDetails sd
WHERE 
    sd.supplier_status <> 'No Supplier'
ORDER BY 
    sd.total_spent DESC, sd.supplier_status;
