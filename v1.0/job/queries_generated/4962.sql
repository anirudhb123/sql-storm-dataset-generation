WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(CASE 
            WHEN ci.nr_order IS NOT NULL THEN ci.nr_order 
            ELSE 0 
        END) AS avg_order,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        rm.avg_order,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_title, rm.production_year, rm.actor_count, rm.avg_order
    HAVING 
        COUNT(DISTINCT k.id) > 0
),
TopMovies AS (
    SELECT 
        mwk.movie_title,
        mwk.production_year,
        mwk.actor_count,
        mwk.avg_order,
        CASE 
            WHEN mwk.actor_count > 10 THEN 'High'
            WHEN mwk.actor_count BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS actor_category
    FROM 
        MoviesWithKeywords mwk
    WHERE 
        mwk.production_year >= 2000
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    tm.avg_order,
    tm.actor_category,
    STRING_AGG(mk.linked_movie_id::TEXT, ', ') AS related_movies
FROM 
    TopMovies tm
LEFT JOIN 
    movie_link ml ON tm.movie_title = ml.movie_id
LEFT JOIN 
    title t ON ml.linked_movie_id = t.imdb_id
GROUP BY 
    tm.movie_title, tm.production_year, tm.actor_count, tm.avg_order, tm.actor_category
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
