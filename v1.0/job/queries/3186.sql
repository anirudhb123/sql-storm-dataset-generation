
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank_per_year <= 5
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT ak.name), 'No Actors') AS actors,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name), 'No Companies') AS companies
    FROM 
        top_movies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
keyword_summary AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.companies,
    ks.keyword_count,
    ks.keywords
FROM 
    movie_details md
JOIN 
    keyword_summary ks ON md.movie_id = ks.movie_id
WHERE 
    ks.keyword_count > 0
ORDER BY 
    md.production_year DESC, md.title;
