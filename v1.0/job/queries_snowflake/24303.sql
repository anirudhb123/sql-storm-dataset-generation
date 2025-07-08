WITH RankedTitles AS (
    SELECT 
        at.id as title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) as title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL 
        AND at.title IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) as movie_count,
        MAX(rt.role) as last_role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
),
GenreKeywordCounts AS (
    SELECT 
        ak.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword ak
    JOIN 
        movie_keyword mk ON ak.id = mk.keyword_id
    GROUP BY 
        ak.keyword
    HAVING 
        COUNT(mk.movie_id) > 5
)
SELECT 
    na.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    ar.last_role,
    COALESCE(gkc.movie_count, 0) AS genre_count,
    CASE 
        WHEN ar.movie_count >= 3 THEN 'Prolific Actor'
        ELSE 'Occasional Actor'
    END AS actor_category
FROM 
    RankedTitles rt
LEFT JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
LEFT JOIN 
    aka_name na ON ci.person_id = na.person_id
LEFT JOIN 
    ActorRoleCounts ar ON na.person_id = ar.person_id
LEFT JOIN 
    GenreKeywordCounts gkc ON rt.title LIKE '%' || gkc.keyword || '%'
WHERE 
    rt.title_rank = 1 
    AND (rt.production_year >= 2000 OR ar.movie_count IS NULL)
ORDER BY 
    rt.production_year DESC, 
    rt.title;

