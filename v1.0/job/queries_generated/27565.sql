WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id
),
HighActorCountTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        actor_count,
        actor_names
    FROM 
        RankedTitles
    WHERE 
        rank_within_year <= 3
)
SELECT 
    ht.title,
    ht.production_year,
    ht.actor_count,
    ht.actor_names,
    GROUP_CONCAT(DISTINCT mk.keyword ORDER BY mk.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT mi.info ORDER BY mi.info_type_id) AS additional_info
FROM 
    HighActorCountTitles ht
LEFT JOIN 
    movie_keyword mk ON ht.title_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON ht.title_id = mi.movie_id
WHERE 
    ht.production_year >= 2000 
GROUP BY 
    ht.title_id, ht.title, ht.production_year, ht.actor_count, ht.actor_names
ORDER BY 
    ht.production_year DESC, ht.actor_count DESC;
