WITH 
    RankedMovies AS (
        SELECT 
            t.title,
            t.production_year,
            COUNT(DISTINCT c.person_id) AS cast_count,
            STRING_AGG(DISTINCT a.name, ', ') AS actor_names
        FROM 
            aka_title t
        JOIN 
            cast_info c ON t.id = c.movie_id
        JOIN 
            aka_name a ON c.person_id = a.person_id
        GROUP BY 
            t.id, t.title, t.production_year
    ),
    KeywordRanked AS (
        SELECT 
            m.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords,
            ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY m.production_year DESC) AS keyword_rank
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        JOIN 
            aka_title m ON mk.movie_id = m.id
        GROUP BY 
            m.movie_id
    )
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    kr.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordRanked kr ON rm.title = kr.movie_id
WHERE 
    rm.cast_count > 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
