WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        s.s_nationkey,
        s.s_acctbal,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS part_supplier_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CONCAT('Customer: ', c.c_name, ', Order Total: ', o.o_totalprice) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
AggregateSupplierDetails AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.supplier_name, 
    p.part_supplier_info, 
    c.c_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    c.customer_order_info, 
    a.nation_name, 
    a.total_parts, 
    a.total_account_balance
FROM 
    PartSupplierDetails p
JOIN 
    CustomerOrderDetails c ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps JOIN orders o ON ps.ps_suppkey = o.o_orderkey)
JOIN 
    AggregateSupplierDetails a ON p.s_nationkey = a.nation_name
WHERE 
    o.o_totalprice > 1000 AND
    p.p_name LIKE '%widget%'
ORDER BY 
    a.total_account_balance DESC, 
    c.o_orderdate ASC;
