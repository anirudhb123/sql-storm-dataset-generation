
WITH Recursive_Cast AS (
    SELECT 
        ci.movie_id,
        ka.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
),
Movie_Info_Stats AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT ki.keyword) AS keyword_count,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS description,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id
),
Top_Movies AS (
    SELECT 
        rc.movie_id,
        rc.actor_name,
        rc.actor_order,
        ROW_NUMBER() OVER (ORDER BY mis.keyword_count DESC, rc.movie_id) AS rank
    FROM 
        Recursive_Cast rc
    JOIN 
        Movie_Info_Stats mis ON rc.movie_id = mis.movie_id
    WHERE 
        mis.has_note_ratio > 0.5
),
Filtered_Movies AS (
    SELECT 
        tm.movie_id,
        tm.actor_name,
        tm.actor_order,
        tm.rank,
        COALESCE(sub.title, 'No Related Title') AS related_title
    FROM 
        Top_Movies tm
    LEFT JOIN 
        (SELECT 
             m.id AS movie_id,
             m.title
         FROM 
             aka_title m
         WHERE 
             m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')) sub ON tm.movie_id = sub.movie_id
)
SELECT 
    fm.movie_id,
    fm.actor_name,
    fm.actor_order,
    fm.rank,
    fm.related_title,
    COUNT(mi.id) AS total_movie_info,
    STRING_AGG(DISTINCT mi.info, ', ') AS all_info
FROM 
    Filtered_Movies fm
LEFT JOIN 
    movie_info mi ON fm.movie_id = mi.movie_id
WHERE 
    fm.rank <= 10
GROUP BY 
    fm.movie_id,
    fm.actor_name,
    fm.actor_order,
    fm.rank,
    fm.related_title
ORDER BY 
    fm.rank;
