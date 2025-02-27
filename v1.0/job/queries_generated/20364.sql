WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        b.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(c.person_id) DESC) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name b ON c.person_id = b.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year, b.name
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No additional info') AS additional_info,
        COALESCE(mc.name, 'Unknown Company') AS production_company,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, mi.info, mc.name
),
top_movies AS (
    SELECT 
        r.movie_title,
        r.production_year,
        r.actor_name,
        m.additional_info,
        m.production_company,
        m.keywords,
        COUNT(*) OVER () AS total_movies
    FROM 
        ranked_movies r
    JOIN 
        movie_details m ON r.movie_title = m.title
    WHERE 
        r.actor_rank <= 3
),
final_selection AS (
    SELECT 
        *,
        CASE 
            WHEN production_year IS NULL THEN 'Year Unknown' 
            WHEN production_year < 2010 THEN 'Pre-2010'
            ELSE 'Post-2009' 
        END AS year_category,
        NULLIF(keywords, '') AS keyword_list
    FROM 
        top_movies
    WHERE 
        actor_name NOT LIKE '%Smith%'
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    additional_info,
    production_company,
    keywords,
    year_category,
    CASE 
        WHEN keyword_list IS NULL THEN 'No Keywords Available'
        ELSE keyword_list 
    END AS keyword_evaluation,
    total_movies
FROM 
    final_selection
ORDER BY 
    production_year DESC, actor_name;
