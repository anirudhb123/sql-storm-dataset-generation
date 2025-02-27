WITH MovieCounts AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS actors_with_notes,
        AVG(CASE WHEN kaw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS avg_keywords
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kaw ON mk.keyword_id = kaw.id
    GROUP BY 
        a.id, a.title
),
ActorStats AS (
    SELECT 
        n.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movies_count,
        STRING_AGG(DISTINCT a.title, ', ') AS movie_titles
    FROM 
        name n
    JOIN 
        cast_info c ON n.id = c.person_id
    JOIN 
        aka_title a ON c.movie_id = a.id
    GROUP BY 
        n.id, n.name
),
MovieMetrics AS (
    SELECT 
        mv.movie_title,
        mv.actor_count,
        mv.actors_with_notes,
        mv.avg_keywords,
        STRING_AGG(a.actor_name, ', ') AS actor_list,
        COUNT(DISTINCT m.info) AS total_notes
    FROM 
        MovieCounts mv
    LEFT JOIN 
        ActorStats a ON mv.actor_count > 0
    LEFT JOIN 
        movie_info m ON mv.movie_title = m.info
    GROUP BY 
        mv.movie_title, mv.actor_count, mv.actors_with_notes, mv.avg_keywords
)
SELECT 
    m.movie_title,
    m.actor_count,
    m.actors_with_notes,
    m.avg_keywords,
    m.actor_list,
    m.total_notes
FROM 
    MovieMetrics m
ORDER BY 
    m.actor_count DESC, m.total_notes DESC
LIMIT 10;
