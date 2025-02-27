WITH SupplierDetails AS (
    SELECT
        s.s_name,
        s.s_nationkey,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS total_parts_supplied,
        (SELECT SUM(ps.ps_supplycost * ps.ps_availqty) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS total_supply_cost
    FROM
        supplier s
),
CustomerDetails AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name, c.c_nationkey
),
NationDetails AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_nationkey, n.n_name
)
SELECT
    sd.s_name,
    cd.c_name,
    nd.n_name,
    sd.total_parts_supplied,
    sd.total_supply_cost,
    cd.total_spent,
    nd.total_suppliers
FROM
    SupplierDetails sd
JOIN
    CustomerDetails cd ON cd.c_nationkey = sd.s_nationkey
JOIN
    NationDetails nd ON nd.n_nationkey = sd.s_nationkey
WHERE
    sd.total_parts_supplied > 10
ORDER BY
    cd.total_spent DESC, sd.total_supply_cost DESC;
