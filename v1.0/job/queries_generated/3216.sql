WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mr.movie_id,
        mr.title,
        mr.production_year,
        ci.person_role_id,
        ci.nr_order,
        rn.name AS actor_name,
        ci.note AS role_note,
        ROW_NUMBER() OVER (PARTITION BY mr.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        RankedMovies mr
    LEFT JOIN 
        cast_info ci ON mr.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name rn ON ci.person_id = rn.person_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COUNT(mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    MAX(md.actor_order) AS max_actor_order,
    COALESCE(md.role_note, 'No role note') AS role_note_info,
    CASE 
        WHEN md.production_year BETWEEN 1990 AND 2000 THEN '90s'
        WHEN md.production_year > 2000 THEN '2000s or later'
        ELSE 'Before 1990'
    END AS production_decade
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
WHERE 
    md.title IS NOT NULL 
    AND md.actor_name IS NOT NULL
GROUP BY 
    md.movie_id, md.title, md.production_year, md.role_note
ORDER BY 
    md.production_year DESC, keyword_count DESC, md.title;
