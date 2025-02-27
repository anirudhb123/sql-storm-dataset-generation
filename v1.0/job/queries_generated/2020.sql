WITH MovieDetails AS (
    SELECT 
        a.title,
        a.production_year,
        count(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
        MAX(p.gender) AS lead_gender,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        title t ON a.id = t.id
    LEFT JOIN 
        name n ON c.person_id = n.id
    LEFT JOIN 
        person_info p ON n.id = p.person_id AND p.info_type_id = 1 -- assuming 1 for gender
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN actor_count > 5 THEN 'Many Actors' 
            WHEN actor_count BETWEEN 2 AND 5 THEN 'Few Actors' 
            ELSE 'Solo Actor' 
        END AS actor_group
    FROM 
        MovieDetails
    WHERE 
        lead_gender IS NOT NULL
)
SELECT 
    title,
    production_year,
    actor_count,
    keyword_count,
    actor_group
FROM 
    FilteredMovies
WHERE 
    actor_count IS NOT NULL
ORDER BY 
    production_year DESC, title ASC
LIMIT 100
UNION ALL
SELECT 
    'Total' AS title,
    NULL AS production_year,
    COUNT(*) AS actor_count,
    SUM(keyword_count) AS keyword_count,
    NULL AS actor_group
FROM 
    FilteredMovies;
