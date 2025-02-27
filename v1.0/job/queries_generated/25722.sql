WITH RankedTitles AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
),
KeywordCount AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
TopMovies AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        kc.keyword_count
    FROM 
        RankedTitles rt
    JOIN 
        KeywordCount kc ON rt.id = kc.movie_id
    WHERE 
        rt.actor_rank <= 3
    ORDER BY 
        kc.keyword_count DESC, rt.production_year DESC
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COUNT(DISTINCT ak.name) AS total_actors,
    ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name) AS actor_list
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    tm.movie_title, tm.production_year
ORDER BY 
    total_actors DESC, tm.production_year DESC
LIMIT 10;
