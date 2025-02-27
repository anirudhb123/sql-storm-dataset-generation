WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        th.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        TitleHierarchy th ON t.episode_of_id = th.title_id
),
TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS num_actors,
        AVG(CASE WHEN i.info IS NOT NULL THEN 1 ELSE 0 END) AS avg_info_score
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_info_idx mii ON mii.movie_id = m.id AND mii.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Score%')
    LEFT JOIN 
        TitleHierarchy th ON m.id = th.title_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) >= 5
    ORDER BY 
        num_actors DESC, m.production_year DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.num_actors,
    COALESCE(mi.note, 'No additional info') AS info_note,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mi.note
ORDER BY 
    tm.production_year DESC, tm.num_actors DESC;
