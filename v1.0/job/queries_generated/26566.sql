WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsInfo AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_list
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        ak.person_id, ak.name
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    ai.actor_name,
    ai.movies_count,
    ai.movies_list,
    rt.title,
    rt.production_year,
    rt.kind_id,
    rk.rank_in_top_5
FROM 
    ActorsInfo ai
JOIN 
    RankedTitles rt ON rt.title_rank <= 5
LEFT JOIN 
    (
        SELECT 
            title_id,
            ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS rank_in_top_5
        FROM 
            RankedTitles
    ) rk ON rt.title_id = rk.title_id
WHERE 
    ai.movies_count > 5
ORDER BY 
    ai.movies_count DESC, rt.production_year DESC;
