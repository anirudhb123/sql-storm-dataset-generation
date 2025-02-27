WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS year_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ct.kind_id) AS num_roles,
        RANK() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT ct.kind_id) DESC) AS role_rank
    FROM 
        aka_name a
        JOIN cast_info ci ON a.person_id = ci.person_id
        JOIN aka_title at ON ci.movie_id = at.id
        LEFT JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        a.id, a.name, at.title, at.production_year
),
LongRunningSeries AS (
    SELECT 
        t.title,
        COUNT(DISTINCT t.episode_of_id) AS episodes_count,
        MAX(t.season_nr) AS max_season
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%series%')
    GROUP BY 
        t.title
    HAVING 
        COUNT(DISTINCT t.season_nr) > 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
    GROUP BY 
        mk.movie_id
)
SELECT 
    lm.title AS series_title,
    lm.episodes_count,
    lm.max_season,
    at.actor_name,
    at.movie_title,
    mk.keywords,
    CASE 
        WHEN lm.max_season IS NULL THEN 'No seasons'
        WHEN lm.episodes_count > 100 THEN 'Long series'
        ELSE 'Standard series'
    END AS series_category,
    RANK() OVER (PARTITION BY lm.title ORDER BY lm.episodes_count DESC) AS episode_rank,
    COALESCE(NULLIF(at.num_roles, 0), -1) AS role_count
FROM 
    LongRunningSeries lm
    LEFT JOIN ActorTitles at ON lm.title = at.movie_title
    LEFT JOIN MovieKeywords mk ON lm.title = mk.movie_id
WHERE 
    COALESCE(at.role_rank, 0) < 5
ORDER BY 
    lm.episodes_count DESC, lm.title;
