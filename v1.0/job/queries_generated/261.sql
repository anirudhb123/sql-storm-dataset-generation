WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(SUM(CASE WHEN mk.keyword IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count,
        AVG(CASE WHEN i.info IS NOT NULL THEN LENGTH(i.info) ELSE NULL END) AS avg_info_length,
        STRING_AGG(DISTINCT c.name, ', ' ORDER BY c.name) AS company_names
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        movie_keyword AS mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies AS mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN 
        movie_info AS i ON rm.movie_id = i.movie_id
    GROUP BY 
        rm.movie_id, rm.title
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword_count,
    md.avg_info_length,
    md.company_names
FROM 
    MovieDetails AS md
INNER JOIN 
    (SELECT movie_id FROM complete_cast WHERE status_id = 1) AS cc ON md.movie_id = cc.movie_id
INNER JOIN 
    (SELECT 
         movie_id, 
         COUNT(DISTINCT person_id) AS actor_count 
     FROM 
         cast_info 
     GROUP BY 
         movie_id 
     HAVING 
         COUNT(DISTINCT person_id) > 10) AS ac ON md.movie_id = ac.movie_id
WHERE 
    md.keyword_count > 0
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
