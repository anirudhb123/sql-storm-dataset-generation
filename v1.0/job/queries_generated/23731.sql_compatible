
WITH TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT mc.company_id) AS num_producers
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
PersonInfo AS (
    SELECT 
        ci.movie_id,
        a.person_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredTitles AS (
    SELECT 
        ti.title_id,
        ti.title,
        ti.production_year,
        ti.num_producers,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        TitleInfo ti
    LEFT JOIN 
        KeywordCounts kc ON ti.title_id = kc.movie_id
    WHERE 
        ti.production_year IS NOT NULL 
        AND ti.num_producers > 0
),
ActorAnalysis AS (
    SELECT 
        pi.movie_id,
        STRING_AGG(pi.name, ', ') AS actors,
        MAX(pi.actor_rank) AS max_rank
    FROM 
        PersonInfo pi
    GROUP BY 
        pi.movie_id
)

SELECT 
    ft.title,
    ft.production_year,
    COALESCE(aa.actors, 'No actors available') AS actors,
    ft.num_producers,
    ft.keyword_count
FROM 
    FilteredTitles ft
LEFT JOIN 
    ActorAnalysis aa ON ft.title_id = aa.movie_id
ORDER BY 
    ft.production_year DESC,
    ft.keyword_count DESC;
