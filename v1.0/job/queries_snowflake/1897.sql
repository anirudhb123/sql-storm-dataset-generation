WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.imdb_index) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
HighestRatedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ci.role_id,
        COUNT(ci.person_id) AS cast_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        cast_info ci ON rt.title_id = ci.movie_id
    WHERE 
        rt.rank = 1
    GROUP BY 
        rt.title_id, rt.title, rt.production_year, ci.role_id
),
PopularActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count,
        dt.production_year,
        RANK() OVER (PARTITION BY dt.production_year ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        HighestRatedTitles dt ON ci.movie_id = dt.title_id
    WHERE 
        dt.title_id IS NOT NULL
    GROUP BY 
        a.id, a.name, dt.production_year
    HAVING 
        COUNT(ci.movie_id) > 5
)
SELECT 
    p.name AS actor_name,
    p.actor_rank,
    h.production_year,
    h.cast_count,
    CASE 
        WHEN h.cast_count IS NULL THEN 'No Cast'
        ELSE 'Casts Available'
    END AS cast_status
FROM 
    PopularActors p
LEFT JOIN 
    HighestRatedTitles h ON p.production_year = h.production_year
WHERE 
    p.actor_rank <= 10
ORDER BY 
    h.production_year DESC, p.actor_rank ASC;
