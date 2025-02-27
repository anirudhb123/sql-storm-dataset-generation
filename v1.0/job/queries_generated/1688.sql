WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.production_year >= 2000
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(ci.movie_id) >= 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rt.movie_title,
    rt.production_year,
    ak.actor_name,
    COALESCE(mk.keywords_list, 'No Keywords') AS keywords,
    CASE 
        WHEN rt.production_year < 2010 THEN 'Before 2010'
        ELSE '2010 and After'
    END AS year_category
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorMovies ak ON rt.title_rank = ak.movie_count
LEFT JOIN 
    MovieKeywords mk ON rt.movie_id = mk.movie_id
WHERE 
    rt.title_rank <= 10
ORDER BY 
    rt.production_year DESC, rt.movie_title ASC;
