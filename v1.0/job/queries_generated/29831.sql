WITH ActorMovieCount AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 10
),
TopMovies AS (
    SELECT 
        title.title AS movie_title,
        COUNT(DISTINCT keyword.keyword) AS keyword_count
    FROM 
        aka_title title
    JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    JOIN 
        keyword keyword ON mk.keyword_id = keyword.id
    WHERE 
        title.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        title.title
    HAVING 
        COUNT(DISTINCT keyword.keyword) > 5
),
ActorKeywordStats AS (
    SELECT 
        am.actor_name,
        tm.movie_title,
        COUNT(DISTINCT keyword.keyword) AS common_keyword_count
    FROM 
        ActorMovieCount am
    JOIN 
        cast_info ci ON am.actor_name = (SELECT ak.name FROM aka_name ak WHERE ak.person_id = ci.person_id)
    JOIN 
        aka_title at ON ci.movie_id = at.id
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword keyword ON mk.keyword_id = keyword.id
    JOIN 
        TopMovies tm ON at.title = tm.movie_title
    GROUP BY 
        am.actor_name, tm.movie_title
)
SELECT 
    actor_name,
    movie_title,
    common_keyword_count
FROM 
    ActorKeywordStats
ORDER BY 
    actor_name, common_keyword_count DESC;
