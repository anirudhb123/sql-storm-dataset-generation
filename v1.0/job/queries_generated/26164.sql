WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
), KeywordFrequency AS (
    SELECT 
        k.keyword,
        COUNT(m.movie_id) AS movie_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        k.keyword
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.actor_count,
    rm.actor_names,
    kf.keyword,
    kf.movie_count
FROM 
    RankedMovies rm
JOIN 
    KeywordFrequency kf ON rm.keyword_count > kf.movie_count
ORDER BY 
    rm.actor_count DESC, rm.production_year ASC, rm.movie_title;
