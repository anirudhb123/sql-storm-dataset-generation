WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank,
        COALESCE(k.keyword, 'No keyword') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),
movie_statistics AS (
    SELECT 
        r.movie_id,
        COUNT(c.id) AS cast_member_count,
        MAX(y.season_nr) AS max_season,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_note_present
    FROM 
        ranked_movies r
    LEFT JOIN 
        complete_cast cc ON r.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_title y ON r.movie_id = y.id AND y.season_nr IS NOT NULL
    GROUP BY 
        r.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ms.cast_member_count,
    ms.max_season,
    CASE 
        WHEN ms.avg_note_present > 0.5 THEN 'Many notes' 
        ELSE 'Few notes' 
    END AS note_summary
FROM 
    ranked_movies rm
JOIN 
    movie_statistics ms ON rm.movie_id = ms.movie_id
ORDER BY 
    rm.production_year DESC, 
    ms.cast_member_count DESC
LIMIT 50;
