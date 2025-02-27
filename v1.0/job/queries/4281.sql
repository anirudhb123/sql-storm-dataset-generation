
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
    HAVING 
        SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) > 2
),
KeywordCount AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.company_names,
    COALESCE(kc.keyword_total, 0) AS total_keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCount kc ON md.movie_id = kc.movie_id
WHERE 
    EXISTS (SELECT 1 FROM RankedMovies rm WHERE rm.movie_id = md.movie_id AND rm.actor_rank <= 5)
    AND md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.company_count DESC;
