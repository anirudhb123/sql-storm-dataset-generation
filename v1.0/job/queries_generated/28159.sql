WITH RankedTitles AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON ci.movie_id = at.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        at.production_year >= 2000
),
MovieInfo AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY 
        mk.movie_id
),
CompleteMovieData AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        rt.actor_name,
        mi.keywords,
        ROW_NUMBER() OVER (ORDER BY rt.production_year DESC) AS movie_rank
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MovieInfo mi ON rt.movie_title = mi.movie_id
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    keywords
FROM 
    CompleteMovieData
WHERE 
    movie_rank <= 10
ORDER BY 
    production_year DESC, actor_name;
