WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(ki.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS row_num
    FROM 
        RankedMovies m
    LEFT JOIN 
        (SELECT 
            mk.movie_id, 
            COUNT(DISTINCT mk.keyword_id) AS keyword_count
         FROM 
            movie_keyword mk
         GROUP BY 
            mk.movie_id) ki ON m.movie_id = ki.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    (SELECT STRING_AGG(n.name, ', ')
     FROM name n
     JOIN cast_info ci ON n.id = ci.person_id
     WHERE ci.movie_id = md.movie_id) AS lead_actors,
    (SELECT 
         COUNT(DISTINCT mc.company_id)
     FROM 
         movie_companies mc
     WHERE 
         mc.movie_id = md.movie_id) AS company_count
FROM 
    MovieDetails md
WHERE 
    md.actor_count_rank = 1
    AND md.row_num <= 10
ORDER BY 
    md.production_year DESC, md.keyword_count DESC
LIMIT 20;
