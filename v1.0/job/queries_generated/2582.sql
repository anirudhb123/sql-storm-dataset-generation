WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
),
extended_movie_info AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mi.info, 'No info available') AS additional_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rank_by_cast <= 10
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, mi.info
)
SELECT 
    emi.movie_id,
    emi.title,
    emi.production_year,
    emi.additional_info,
    emi.keyword_count,
    COALESCE(ak.name, 'Unknown') AS known_alias
FROM 
    extended_movie_info emi
LEFT JOIN 
    aka_title at ON emi.movie_id = at.movie_id
LEFT JOIN 
    aka_name ak ON at.id = ak.id
WHERE 
    emi.keyword_count > 0
ORDER BY 
    emi.production_year DESC, emi.keyword_count DESC;
