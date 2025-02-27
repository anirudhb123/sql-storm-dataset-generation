WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year > 2000
        AND ci.nr_order IS NOT NULL
),
MovieSummary AS (
    SELECT 
        title,
        production_year,
        STRING_AGG(actor_name, ', ') AS actor_list
    FROM 
        RankedMovies
    GROUP BY 
        title, production_year
),
KeywordedMovies AS (
    SELECT 
        ms.title,
        ms.production_year,
        k.keyword 
    FROM 
        MovieSummary ms
    JOIN 
        movie_keyword mk ON ms.title = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    km.production_year,
    km.title,
    km.keyword,
    COUNT(km.keyword) OVER (PARTITION BY km.production_year) AS keyword_count,
    STRING_AGG(DISTINCT actor_name, ', ') OVER (PARTITION BY km.title) AS all_actors
FROM 
    KeywordedMovies km
JOIN 
    RankedMovies rm ON km.title = rm.title AND km.production_year = rm.production_year
ORDER BY 
    km.production_year DESC, keyword_count DESC;
