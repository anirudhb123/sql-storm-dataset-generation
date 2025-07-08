
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(COALESCE(CAST(SUBSTRING(a.name, '[0-9]+') AS INTEGER), 0)) AS avg_name_number
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies,
        SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS prod_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    r.kind_id,
    COALESCE(cd.actor_count, 0) AS actor_count,
    COALESCE(ci.companies, 'No companies') AS companies,
    COALESCE(ci.prod_count, 0) AS production_companies,
    RANK() OVER (ORDER BY r.production_year DESC) AS year_rank
FROM 
    RankedMovies r
LEFT JOIN 
    CastDetails cd ON r.title_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON r.title_id = ci.movie_id
WHERE 
    r.rn <= 10
GROUP BY 
    r.title_id, r.title, r.production_year, r.kind_id, cd.actor_count, ci.companies, ci.prod_count
ORDER BY 
    r.production_year DESC, r.title;
