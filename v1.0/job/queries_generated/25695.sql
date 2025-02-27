WITH movie_ranked AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count,
        COALESCE(SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS has_ordered_cast,
        COALESCE(mci.total_companies, 0) AS total_companies
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(mc.company_id) AS total_companies
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) mci ON m.id = mci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),

rankings AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS cast_rank
    FROM 
        movie_ranked
)

SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.keywords,
    r.cast_count,
    r.has_ordered_cast,
    r.total_companies,
    CASE 
        WHEN r.cast_count > 5 THEN 'Popular'
        WHEN r.cast_count BETWEEN 1 AND 5 THEN 'Moderate'
        ELSE 'Unknown'
    END AS popularity_status
FROM 
    rankings r
WHERE 
    r.production_year >= 2000
ORDER BY 
    r.cast_rank
LIMIT 50;

This SQL query aggregates details about movies released from 2000 onwards, focusing on their keyword associations, cast counts, and company associations. The result ranks movies primarily by their cast size, categorizing their popularity based on the number of cast members and outputting relevant information to benchmark string processing capabilities across various joins.
