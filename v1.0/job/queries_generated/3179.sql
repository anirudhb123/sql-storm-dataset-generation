WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title, t.production_year
),
CompanyCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cc.company_count, 0) AS company_count,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    MAX(dp.note) AS max_note
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.title = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    CompanyCounts cc ON cc.movie_id = rm.movie_id
LEFT JOIN 
    movie_info dp ON dp.movie_id = cc.movie_id AND dp.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
WHERE 
    rm.actor_count_rank <= 10 
GROUP BY 
    rm.title, rm.production_year, cc.company_count
HAVING 
    COUNT(DISTINCT ci.person_id) >= 5
ORDER BY 
    rm.production_year DESC, total_actors DESC;
