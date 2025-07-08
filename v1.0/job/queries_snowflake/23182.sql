
WITH TitleHierarchy AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        COALESCE(NULLIF(t.season_nr, 0), 1) AS season_adj, 
        NULLIF(t.episode_nr, 0) AS episode_adj
    FROM
        aka_title t
    WHERE
        t.production_year = (
            SELECT MAX(production_year) FROM aka_title
        )
    UNION ALL
    SELECT
        th.title_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        COALESCE(NULLIF(t.season_nr, 0), 1) AS season_adj,
        NULLIF(t.episode_nr, 0) AS episode_adj
    FROM
        aka_title t
    INNER JOIN TitleHierarchy th ON t.episode_of_id = th.title_id
),
MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS character_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    INNER JOIN aka_name a ON c.person_id = a.person_id
    INNER JOIN role_type r ON c.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    INNER JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
DetailedMovies AS (
    SELECT 
        th.title_id, 
        th.title,
        th.production_year,
        mc.actor_name,
        mc.character_role,
        mk.keywords,
        CASE 
            WHEN th.season_nr IS NOT NULL THEN 'Series'
            WHEN th.episode_nr IS NOT NULL THEN 'Episode'
            ELSE 'Feature Film'
        END AS movie_type
    FROM 
        TitleHierarchy th
    LEFT JOIN MovieCast mc ON th.title_id = mc.movie_id
    LEFT JOIN MovieKeywords mk ON th.title_id = mk.movie_id
)
SELECT 
    title,
    production_year,
    actor_name,
    character_role,
    keywords,
    movie_type,
    COUNT(*) OVER (PARTITION BY movie_type) AS type_count,
    NTILE(3) OVER (ORDER BY production_year DESC) AS year_quartile
FROM 
    DetailedMovies
WHERE 
    (keywords LIKE '%action%' OR (keywords IS NULL AND character_role IS NOT NULL))
    OR (movie_type = 'Feature Film' AND production_year > 2000)
ORDER BY 
    year_quartile, 
    title;
