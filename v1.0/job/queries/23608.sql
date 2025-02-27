WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS actor_rank,
        COUNT(t.title) OVER (PARTITION BY a.person_id) AS title_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
UniqueMovieTitles AS (
    SELECT DISTINCT 
        rt.actor_name,
        rt.movie_title,
        rt.production_year,
        rt.actor_rank,
        rt.title_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.actor_rank = 1
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id, k.keyword
    HAVING 
        COUNT(mk.id) > 1
)
SELECT 
    u.actor_name,
    u.movie_title,
    u.production_year,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN EXTRACT(YEAR FROM cast('2024-10-01' as date)) - u.production_year > 10 THEN 'Classic'
        ELSE 'Recent'
    END AS movie_age_category
FROM 
    UniqueMovieTitles u
LEFT JOIN 
    MovieKeywords mk ON u.movie_title = mk.keyword
WHERE 
    (u.title_count > 1 OR u.production_year <> 2000)
    AND u.actor_name IS NOT NULL
ORDER BY 
    u.actor_name, u.production_year DESC
FETCH FIRST 10 ROWS ONLY;