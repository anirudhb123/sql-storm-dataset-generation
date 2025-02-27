WITH RecursiveCast AS (
    SELECT 
        ci.movie_id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        a.name AS director_name, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id AND ci.role_id = (SELECT id FROM role_type WHERE role = 'Director')
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year, a.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id, 
    md.movie_title, 
    md.production_year, 
    md.director_name, 
    rc.actor_count, 
    COALESCE(mk.keywords, 'No keywords') AS keywords, 
    md.company_count
FROM 
    MovieDetails md
LEFT JOIN 
    RecursiveCast rc ON md.movie_id = rc.movie_id
LEFT JOIN 
    MovieKeywords mk ON md.movie_id = mk.movie_id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    rc.actor_count DESC;
