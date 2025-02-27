WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TotalSupplierParts AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(p.p_retailprice) AS avg_retail_price,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        SupplierParts s
    GROUP BY 
        s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY s.total_available_quantity DESC) AS quantity_rank,
        RANK() OVER (ORDER BY s.total_cost DESC) AS cost_rank
    FROM 
        TotalSupplierParts s
)
SELECT 
    r.s_name,
    r.total_available_quantity,
    r.avg_retail_price,
    r.total_cost,
    r.quantity_rank,
    r.cost_rank
FROM 
    RankedSuppliers r
WHERE 
    r.quantity_rank <= 10 OR r.cost_rank <= 10
ORDER BY 
    r.quantity_rank, r.cost_rank;
