WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keywords, '') AS keywords,
        COUNT(cc.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN (
        SELECT 
            movie_id,
            STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) mk ON t.id = mk.movie_id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
rated_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.cast_count,
        RANK() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS rank
    FROM 
        movie_details md
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.cast_count,
    CASE 
        WHEN rm.rank <= 10 THEN 'Top Rated'
        ELSE 'Other'
    END AS rank_category
FROM 
    rated_movies rm
WHERE 
    rm.production_year >= 2000
    AND rm.cast_count > (
        SELECT 
            AVG(cast_count) 
        FROM (
            SELECT 
                COUNT(person_id) AS cast_count
            FROM 
                cast_info
            GROUP BY 
                movie_id
        ) AS avg_cast
    )
ORDER BY 
    rm.rank, rm.title
LIMIT 50;
