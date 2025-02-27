WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        ca.name AS actor_name,
        1 AS depth
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    WHERE 
        ci.movie_id IN (
            SELECT 
                movie_id 
            FROM 
                title 
            WHERE 
                production_year >= 2000
        )
    UNION ALL
    SELECT 
        ci.person_id,
        ca.name AS actor_name,
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    JOIN 
        ActorHierarchy ah ON ci.movie_id = (
            SELECT 
                linked_movie_id 
            FROM 
                movie_link ml
            WHERE 
                ml.movie_id = ah.movie_id
            LIMIT 1
        )
    WHERE 
        ah.depth < 5
),
MovieStats AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(distinct ci.person_id) AS actor_count,
        AVG(m.production_year) AS avg_production_year
    FROM 
        title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalStats AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.actor_count,
        ks.keyword_count,
        COALESCE(ks.keyword_count, 0) AS keyword_count_filled,
        CASE 
            WHEN ms.avg_production_year > 2010 THEN 'Modern'
            ELSE 'Classic'
        END AS movie_age_category
    FROM 
        MovieStats ms
    LEFT JOIN 
        KeywordStats ks ON ms.movie_id = ks.movie_id
)
SELECT 
    fs.movie_id,
    fs.title,
    fs.actor_count,
    fs.keyword_count_filled,
    fs.movie_age_category,
    ROW_NUMBER() OVER (PARTITION BY fs.movie_age_category ORDER BY fs.actor_count DESC, fs.keyword_count_filled DESC) AS rank_within_category
FROM 
    FinalStats fs
WHERE 
    fs.actor_count > 5
ORDER BY 
    fs.movie_age_category,
    fs.actor_count DESC,
    fs.keyword_count_filled DESC;
