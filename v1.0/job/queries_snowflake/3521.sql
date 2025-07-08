
WITH movie_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_role_count
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
detailed_movies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.actors,
        ms.has_role_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        movie_summary ms
    LEFT JOIN 
        movie_keywords mk ON ms.movie_id = mk.movie_id
),
ranked_movies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY has_role_count DESC, total_cast DESC) AS rank
    FROM 
        detailed_movies
    WHERE 
        total_cast > 0
)
SELECT 
    dm.title,
    dm.production_year,
    dm.total_cast,
    dm.actors,
    dm.keywords,
    CASE 
        WHEN rank <= 10 THEN 'Top Movie'
        ELSE 'Regular Movie'
    END AS movie_category
FROM 
    ranked_movies dm
WHERE 
    dm.production_year >= 2000
ORDER BY 
    dm.rank;
