WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY m.id) AS production_company_count
    FROM 
        aka_title m 
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    WHERE 
        m.production_year IS NOT NULL
),
featured_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.id) AS movie_count,
        SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
    HAVING 
        COUNT(DISTINCT c.id) > 2
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
valuable_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        fc.actor_name,
        mk.keywords,
        EXISTS (
            SELECT 1 
            FROM complete_cast cc 
            WHERE cc.movie_id = rm.movie_id AND cc.status_id = 1
        ) AS has_complete_cast
    FROM 
        ranked_movies rm
    LEFT JOIN 
        featured_cast fc ON rm.movie_id = fc.movie_id
    LEFT JOIN 
        movie_keywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rank <= 5 AND rm.production_company_count > 0
)
SELECT 
    v.title,
    v.production_year,
    v.actor_name,
    v.keywords,
    CASE 
        WHEN v.has_complete_cast IS TRUE THEN 'Complete Cast'
        ELSE 'Incomplete Cast'
    END AS cast_status,
    COALESCE(v.keywords, 'No keywords available') AS keywords_display
FROM 
    valuable_movies v
WHERE 
    (v.production_year >= 2000 AND v.actor_name ILIKE '%john%') OR 
    (v.production_year < 2000 AND v.actor_name NOT ILIKE '%smith%')
ORDER BY 
    v.production_year DESC,
    v.title;
