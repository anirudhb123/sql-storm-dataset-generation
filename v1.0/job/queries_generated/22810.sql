WITH movie_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(t.kind_id, 0) AS kind_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        AVG(COALESCE(ki.kw_count, 0)) OVER (PARTITION BY m.id) AS avg_keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id AND cn.country_code = 'USA'
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(keyword_id) AS kw_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) ki ON m.id = ki.movie_id
    LEFT JOIN 
        kind_type t ON m.kind_id = t.id
    GROUP BY 
        m.id, m.title, m.production_year, t.kind_id
),
ranked_movies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY kind_id ORDER BY total_cast DESC, production_year ASC) AS rank
    FROM 
        movie_summary
)
SELECT 
    r.*,
    CASE 
        WHEN r.actors IS NULL OR r.actors = '' THEN 'No Cast Available'
        ELSE r.actors
    END AS formatted_actors,
    CASE 
        WHEN r.total_cast > 5 THEN 'Large Cast'
        WHEN r.total_cast BETWEEN 1 AND 5 THEN 'Small Cast'
        ELSE 'No Cast'
    END AS cast_size_category,
    CASE 
        WHEN r.production_year IS NULL THEN 'Year Unknown'
        ELSE r.production_year::text
    END AS production_year_str
FROM 
    ranked_movies r
WHERE 
    r.rank <= 10
ORDER BY 
    r.kind_id, r.total_cast DESC;
