WITH RECURSIVE ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
cast_details AS (
    SELECT 
        ci.id,
        a.name AS actor_name,
        t.title AS movie_title,
        c.kind AS role_type
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    LEFT JOIN 
        comp_cast_type c ON ci.role_id = c.id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS movie_information
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NOT NULL
    GROUP BY 
        mi.movie_id
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
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mkd.keywords, 'No Keywords') AS keywords,
    COALESCE(mid.movie_information, 'No Information Available') AS movie_information,
    CASE 
        WHEN rm.cast_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mkd ON rm.movie_id = mkd.movie_id
LEFT JOIN 
    movie_info_details mid ON rm.movie_id = mid.movie_id
WHERE 
    rm.rank <= 10 
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;