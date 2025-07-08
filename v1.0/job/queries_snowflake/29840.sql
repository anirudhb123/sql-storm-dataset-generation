
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(mk.id) AS keyword_count,
        COUNT(DISTINCT cc.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        RANK() OVER (ORDER BY COUNT(mk.id) DESC) AS keyword_rank,
        RANK() OVER (ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info cc ON t.id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        keyword_count,
        actor_count,
        actors,
        companies,
        keyword_rank,
        actor_rank
    FROM 
        RankedMovies
    WHERE 
        keyword_rank <= 10 OR actor_rank <= 10
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword_count,
    actor_count,
    ARRAY_TO_STRING(actors, ', ') AS actors,
    ARRAY_TO_STRING(companies, ', ') AS companies
FROM 
    TopRatedMovies
ORDER BY 
    keyword_count DESC, actor_count DESC;
