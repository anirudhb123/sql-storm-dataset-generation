WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        0 AS level
    FROM aka_name a
    WHERE a.name IS NOT NULL

    UNION ALL

    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ah.level + 1
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN ActorHierarchy ah ON c.movie_id = ah.actor_id
    WHERE a.name IS NOT NULL
),

MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS title,
        m.production_year AS year,
        km.keyword AS keyword,
        STRING_AGG(DISTINCT a.name, ', ') AS cast,
        COUNT(DISTINCT k.id) AS keyword_count,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT k.id) DESC) AS keyword_rank
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    WHERE m.production_year IS NOT NULL
    GROUP BY m.id, m.title, m.production_year, km.keyword
),

FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.year,
        md.cast,
        md.keyword_count,
        md.keyword_rank
    FROM MovieDetails md
    WHERE md.year > 2000 
        AND md.keyword_count > 5
),

FinalReport AS (
    SELECT 
        fm.title,
        fm.year,
        fm.cast,
        fm.keyword_count,
        ah.level AS actor_hierarchy_level
    FROM FilteredMovies fm
    LEFT JOIN ActorHierarchy ah ON ah.actor_id::text = fm.cast::text
)

SELECT 
    fr.title,
    fr.year,
    fr.cast,
    fr.keyword_count,
    COALESCE(fr.actor_hierarchy_level, 0) AS actor_hierarchy_level
FROM FinalReport fr
WHERE fr.actor_hierarchy_level IS NOT NULL
ORDER BY fr.year DESC, fr.keyword_count DESC;
