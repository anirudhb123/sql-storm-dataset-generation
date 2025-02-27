WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_type LIKE 'Rubber%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'SPECIAL'
)
SELECT 
    COALESCE(cu.c_name, 'Unknown Customer') AS CustomerName,
    COUNT(DISTINCT co.o_orderkey) AS TotalOrders,
    SUM(fp.ps_availqty) AS TotalAvailableParts,
    SUM(fp.ps_supplycost * fp.ps_availqty) AS TotalSupplyCost,
    STUFF(
        (SELECT ', ' + rs.s_name
         FROM RankedSuppliers rs
         WHERE rs.rank <= 3 AND rs.s_nationkey = cu.c_nationkey
         FOR XML PATH('')), 
        1, 2, '') AS TopSuppliers
FROM 
    CustomerOrders co
LEFT JOIN 
    FilteredParts fp ON co.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20)
    )
LEFT JOIN 
    customer cu ON co.c_custkey = cu.c_custkey
GROUP BY 
    cu.c_name;
