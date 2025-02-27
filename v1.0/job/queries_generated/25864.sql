WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS all_keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON ci.movie_id = mt.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.movie_id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        total_cast,
        all_aka_names,
        all_keywords
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 5  -- Top 5 movies per year based on cast size
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.all_aka_names,
    tm.all_keywords,
    ci.role_id,
    rt.role
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    role_type rt ON rt.id = ci.person_role_id
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
