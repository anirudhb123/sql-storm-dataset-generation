
WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.depth + 1
    FROM 
        aka_title t
    JOIN 
        MovieCTE m ON t.episode_of_id = m.movie_id
    WHERE 
        t.episode_of_id IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rn
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IN ('Actor', 'Actress')
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    LISTAGG(DISTINCT f.actor_name, ', ') WITHIN GROUP (ORDER BY f.actor_name) AS actors,
    COUNT(DISTINCT ci.company_name) AS distinct_company_count,
    MAX(ci.company_count) AS max_companies_involved
FROM 
    MovieCTE m
LEFT JOIN 
    FilteredCast f ON m.movie_id = f.movie_id
LEFT JOIN 
    CompanyInfo ci ON m.movie_id = ci.movie_id
WHERE 
    m.depth <= 2
GROUP BY 
    m.movie_id, m.title, m.production_year
ORDER BY 
    m.production_year DESC, m.title;
