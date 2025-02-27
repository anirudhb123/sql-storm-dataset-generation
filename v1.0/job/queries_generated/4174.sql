WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_note_presence
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    LEFT JOIN 
        info_type it ON pi.info_type_id = it.id
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        avg_cast_note_presence,
        RANK() OVER (ORDER BY total_cast DESC) AS cast_rank
    FROM 
        movie_details
)
SELECT 
    mv.title,
    mv.production_year,
    COALESCE(CAST(mv.total_cast AS VARCHAR), 'No Cast') AS cast_count,
    CASE 
        WHEN mv.avg_cast_note_presence > 0.5 THEN 'Mostly Available Notes'
        WHEN mv.avg_cast_note_presence IS NULL THEN 'No Data'
        ELSE 'Few Available Notes'
    END AS note_availability,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mv.movie_id) AS keyword_count
FROM 
    top_movies mv
WHERE 
    mv.cast_rank <= 10
ORDER BY 
    mv.cast_rank;
