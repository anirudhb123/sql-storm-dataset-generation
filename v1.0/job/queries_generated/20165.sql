WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM aka_title WHERE title ILIKE '%Sequel%')
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        actor_hierarchy ah ON ci.movie_id IN (
            SELECT movie_id FROM movie_link ml 
            WHERE ml.linked_movie_id IN (
                SELECT movie_id FROM aka_title 
                WHERE title ILIKE '%Sequel%'
            )
        )
    WHERE 
        ah.person_id <> ci.person_id
),
performance_benchmark AS (
    SELECT 
        at.production_year,
        COUNT(DISTINCT ca.actor_name) AS unique_actors,
        STRING_AGG(DISTINCT at.title, ', ') AS titles_in_year,
        SUM(
            CASE 
                WHEN mi.info IS NOT NULL THEN 1 
                ELSE 0 
            END
        ) AS info_records_count
    FROM 
        aka_title at 
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        actor_hierarchy ah ON ci.person_id = ah.person_id
    LEFT JOIN 
        movie_info mi ON at.movie_id = mi.movie_id
    WHERE 
        at.production_year > 2000 AND at.kind_id IN (
            SELECT id FROM kind_type WHERE kind ILIKE 'feature%'
        )
    GROUP BY 
        at.production_year
)
SELECT 
    pb.production_year,
    pb.unique_actors,
    pb.titles_in_year,
    pb.info_records_count,
    COALESCE(ROW_NUMBER() OVER (PARTITION BY pb.production_year ORDER BY pb.unique_actors DESC), 0) AS rank,
    CASE 
        WHEN pb.unique_actors > 10 THEN 'Highly Collaborated'
        WHEN pb.unique_actors BETWEEN 5 AND 10 THEN 'Moderately Collaborated'
        ELSE 'Less Collaborated'
    END AS collaboration_level
FROM 
    performance_benchmark pb
ORDER BY 
    pb.production_year DESC,
    pb.unique_actors DESC
LIMIT 15;
