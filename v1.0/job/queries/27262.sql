
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
TitleKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    WHERE 
        mi.info LIKE '%best%' 
    GROUP BY 
        mk.movie_id
), 
ActorStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT a.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
) 
SELECT 
    r.title,
    r.production_year,
    r.kind_id,
    ak.actor_count,
    ak.actor_names,
    k.keyword_count
FROM 
    RankedTitles r
LEFT JOIN 
    ActorStats ak ON r.title_id = ak.movie_id
LEFT JOIN 
    TitleKeywordCounts k ON r.title_id = k.movie_id
WHERE 
    r.title_rank <= 5 
ORDER BY 
    r.production_year ASC, 
    r.title ASC;
