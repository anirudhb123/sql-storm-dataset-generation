WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY YEAR(t.production_year) ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieCast AS (
    SELECT 
        cc.movie_id,
        c.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY cc.movie_id ORDER BY cc.nr_order) AS actor_rank
    FROM 
        cast_info cc
    JOIN 
        aka_name c ON cc.person_id = c.person_id
), 
IndependentMovies AS (
    SELECT
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        m.movie_id
    HAVING 
        COUNT(mk.keyword_id) > 3
)
SELECT 
    rm.title,
    rm.production_year,
    mc.actor_name,
    im.keyword_count,
    (SELECT COUNT(*) FROM movie_companies WHERE movie_id = rm.movie_id) AS company_count,
    (SELECT STRING_AGG(name, ', ') FROM company_name cn JOIN movie_companies mc ON cn.id = mc.company_id WHERE mc.movie_id = rm.movie_id) AS companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id AND mc.actor_rank <= 3
LEFT JOIN 
    IndependentMovies im ON rm.movie_id = im.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
