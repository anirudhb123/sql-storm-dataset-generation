
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rnk
    FROM
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ',') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    MK.keywords,
    CASE 
        WHEN t.production_year = (SELECT MAX(production_year) FROM title) THEN 'Latest Release'
        ELSE 'Earlier Release'
    END AS release_status,
    CASE 
        WHEN MK.keywords IS NULL THEN 'No Keywords'
        WHEN ARRAY_SIZE(SPLIT(MK.keywords, ',')) > 3 THEN 'Rich in Keywords'
        ELSE 'Moderate Keywords'
    END AS keyword_category
FROM 
    RankedTitles t
LEFT JOIN 
    ActorCount ac ON t.title_id = ac.movie_id
LEFT JOIN 
    MovieKeywords MK ON t.title_id = MK.movie_id
WHERE 
    t.rnk <= 10 AND 
    (t.production_year > 2000 OR t.production_year IS NULL)
ORDER BY 
    t.production_year DESC, total_actors DESC
LIMIT 50;
