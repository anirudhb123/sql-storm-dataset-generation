WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mv.linked_movie_id AS movie_id, 
        t.title, 
        t.production_year,
        mh.level + 1
    FROM movie_link mv
    JOIN title t ON mv.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON mv.movie_id = mh.movie_id
),
ActorStats AS (
    SELECT 
        a.person_id, 
        a.id AS cast_id,
        COUNT(*) AS total_movies,
        MAX(t.production_year) AS latest_movie_year
    FROM cast_info a
    JOIN title t ON a.movie_id = t.id
    GROUP BY a.person_id, a.id
),
RankedActors AS (
    SELECT 
        a.person_id, 
        a.total_movies, 
        a.latest_movie_year,
        RANK() OVER (ORDER BY a.total_movies DESC, a.latest_movie_year DESC) AS rank
    FROM ActorStats a
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(DISTINCT n.name, ', ') AS actors,
        m.production_year
    FROM title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN aka_name n ON c.person_id = n.person_id
    GROUP BY m.id, m.title, m.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(ra.total_movies, 0) AS actor_count,
    COALESCE(ra.latest_movie_year, 'N/A') AS latest_actor_year,
    mh.level AS movie_hierarchy_level
FROM MovieDetails md
LEFT JOIN RankedActors ra ON md.movie_id = ra.person_id
LEFT JOIN MovieHierarchy mh ON md.movie_id = mh.movie_id
WHERE md.production_year > 2000
ORDER BY md.production_year DESC, actor_count DESC;

