WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(DISTINCT c.person_id) AS num_actors
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.num_actors
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_title <= 10
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name), 'No cast') AS cast_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    CASE 
        WHEN tm.num_actors > 0 THEN ROUND(1.0 * COUNT(DISTINCT mk.keyword) / tm.num_actors, 2)
        ELSE NULL
    END AS avg_keywords_per_actor
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.num_actors
ORDER BY 
    tm.production_year DESC, tm.title;
