
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT CASE WHEN cr.role IS NOT NULL THEN cr.role END) AS distinct_roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type cr ON ci.role_id = cr.id
    GROUP BY 
        ci.person_id
),
MoviesWithKeyword AS (
    SELECT 
        mt.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
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
    rt.title,
    rt.production_year,
    ar.movie_count,
    ar.distinct_roles,
    COALESCE(mkw.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN ar.movie_count > 10 THEN 'Frequent Actor' 
        WHEN ar.movie_count BETWEEN 5 AND 10 THEN 'Moderate Actor' 
        ELSE 'Rare Actor' 
    END AS actor_category
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoleCounts ar ON rt.title_id = ar.person_id
LEFT JOIN 
    MoviesWithKeyword mkw ON rt.title_id = mkw.movie_id
WHERE 
    rt.rank_per_year = 1
ORDER BY 
    rt.production_year DESC, ar.movie_count DESC, rt.title;
