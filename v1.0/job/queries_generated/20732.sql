WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COALESCE(k.keyword, 'No keyword') AS keyword,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        COALESCE(c.kind, 'No Comp Type') AS company_type
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year >= 2000
),
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT title_id) AS title_count
    FROM 
        RankedTitles
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT title_id) > 5
),
FinishingTouches AS (
    SELECT 
        rt.title,
        rt.production_year,
        ac.title_count,
        rt.keyword,
        CASE 
            WHEN rt.title_rank % 2 = 0 THEN 'Even Title Rank'
            ELSE 'Odd Title Rank'
        END AS rank_classification
    FROM 
        RankedTitles rt
    JOIN 
        ActorCount ac ON rt.actor_name = ac.actor_name
)
SELECT 
    ft.title,
    ft.production_year,
    ft.title_count,
    ft.keyword,
    ft.rank_classification,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id IN (SELECT title_id FROM RankedTitles WHERE keyword = ft.keyword)) AS related_movie_info_count,
    CASE 
        WHEN ft.production_year < 2010 THEN 'Pre-2010'
        WHEN ft.production_year BETWEEN 2010 AND 2015 THEN '2010-2015'
        ELSE 'Post-2015'
    END AS production_year_category
FROM 
    FinishingTouches ft
WHERE 
    ft.keyword NOT LIKE 'No keyword'
ORDER BY 
    ft.production_year DESC, 
    ft.title;

