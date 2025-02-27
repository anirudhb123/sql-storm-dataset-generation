WITH Recursive MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        c.name AS company_name,
        r.role,
        t.production_year,
        COUNT(DISTINCT m.id) AS actor_count,
        COALESCE(mo.info, 'No info available') AS movie_note
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_info mo ON t.id = mo.movie_id AND mo.info_type_id IN (
            SELECT id FROM info_type WHERE info LIKE '%Award%' OR info LIKE '%Nominated%'
        )
    GROUP BY 
        t.id, c.name, r.role, t.production_year, mo.info
),
RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        movie_note,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank
    FROM 
        MovieInfo
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.actor_count,
    m.movie_note,
    CASE 
        WHEN m.rank = 1 THEN 'Most Cast'
        WHEN m.rank BETWEEN 2 AND 5 THEN 'Top 5 Cast'
        ELSE 'Others'
    END AS ranking_category
FROM 
    RankedMovies m
WHERE 
    m.production_year IS NOT NULL
    AND (m.actor_count = (SELECT MAX(actor_count) FROM RankedMovies) OR m.actor_count IS NULL)
UNION ALL
SELECT 
    NULL AS movie_id,
    NULL AS title,
    NULL AS production_year,
    COUNT(*) AS total_movies,
    'Aggregated Count' AS movie_note,
    'Summary' AS ranking_category
FROM 
    RankedMovies
WHERE 
    actor_count < 10
ORDER BY 
    production_year DESC NULLS LAST;
