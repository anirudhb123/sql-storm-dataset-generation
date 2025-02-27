WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), RegionalComment AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count,
        STRING_AGG(n.n_name, ', ') AS nations_list
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rp.p_name,
    rp.ps_availqty,
    rp.ps_supplycost,
    co.c_name,
    co.order_count,
    co.total_spent,
    sd.nation_name,
    sd.supplier_rank,
    rc.nation_count,
    rc.nations_list
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON co.order_count > 0
JOIN 
    SupplierDetails sd ON sd.supplier_rank <= 5
JOIN 
    RegionalComment rc ON rc.nation_count > 1
WHERE 
    rp.rank = 1
ORDER BY 
    rp.ps_supplycost DESC, co.total_spent DESC, sd.supplier_rank;
