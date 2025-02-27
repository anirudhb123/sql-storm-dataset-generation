WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ka.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ka ON c.person_id = ka.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS rn
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieSummary AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.actor_count,
        COALESCE(ci.company_name, 'Independent') AS company_name,
        ci.company_type
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyInfo ci ON md.title_id = ci.movie_id AND ci.rn = 1
)
SELECT 
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.company_name,
    STRING_AGG(DISTINCT ms.company_type, ', ') AS company_types
FROM 
    MovieSummary ms
LEFT JOIN 
    movie_info mi ON ms.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
WHERE 
    ms.actor_count > 5
GROUP BY 
    ms.title, ms.production_year, ms.actor_count, ms.company_name
ORDER BY 
    ms.production_year DESC, ms.actor_count DESC;
