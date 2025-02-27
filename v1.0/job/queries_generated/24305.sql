WITH movie_stats AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COALESCE(AVG(CASE WHEN info.info IS NOT NULL THEN LENGTH(info.info) END), 0) AS avg_info_length,
        SUM(CASE WHEN info.info IS NOT NULL AND info.note IS NOT NULL THEN 1 ELSE 0 END) AS info_with_notes
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_info info ON m.id = info.movie_id
    GROUP BY 
        m.id
),
keyword_rank AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        RANK() OVER (PARTITION BY mk.movie_id ORDER BY COUNT(mk.keyword_id) DESC) AS keyword_ranking
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
detailed_cast AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.cast_count,
    ms.keyword_count,
    ms.avg_info_length,
    ms.info_with_notes,
    COALESCE(kr.keyword, 'No Keywords') AS top_keyword,
    COALESCE(d.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(d.actor_order, 0) AS actor_order,
    CASE 
        WHEN ms.info_with_notes > 10 THEN 'Rich Info'
        WHEN ms.info_with_notes = 0 THEN 'No Info'
        ELSE 'Moderate Info'
    END AS info_quality
FROM 
    movie_stats ms
LEFT JOIN 
    keyword_rank kr ON ms.movie_id = kr.movie_id AND kr.keyword_ranking = 1
LEFT JOIN 
    detailed_cast d ON ms.movie_id = d.movie_id
WHERE 
    ms.cast_count > 5 OR d.actor_order IS NOT NULL
ORDER BY 
    ms.avg_info_length DESC, ms.keyword_count DESC, ms.title;
