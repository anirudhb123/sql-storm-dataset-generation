WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (SELECT person_id FROM cast_info ci WHERE ci.movie_id = t.movie_id)
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank_within_year
    FROM 
        movie_details md
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
final_selection AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.aliases,
        rm.cast_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_counts kc ON kc.movie_id = rm.movie_id
    WHERE 
        rm.rank_within_year <= 5
        AND (rm.production_year > 2000 OR rm.keywords IS NULL)
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.aliases,
    f.cast_count,
    f.keyword_count
FROM 
    final_selection f
WHERE 
    f.cast_count > 1 
    AND EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = f.movie_id 
        AND mi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Ratings'
        ) AND mi.info IS NOT NULL
    )
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
