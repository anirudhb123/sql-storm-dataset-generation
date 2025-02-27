WITH ranked_movies AS (
    SELECT 
        tit.id AS movie_id,
        tit.title AS movie_title,
        tit.production_year,
        COUNT(DISTINCT cast.id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT cast.id) DESC) AS rank_by_cast_size
    FROM 
        title tit
    LEFT JOIN 
        cast_info cast ON tit.id = cast.movie_id
    GROUP BY 
        tit.id, tit.title, tit.production_year
),
descriptive_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aliases,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        aka_title ak ON rm.movie_id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.cast_count
)
SELECT 
    dm.movie_id,
    dm.movie_title,
    dm.production_year,
    dm.cast_count,
    dm.aliases,
    dm.keywords,
    ct.kind AS company_type,
    cn.name AS company_name
FROM 
    descriptive_movies dm
LEFT JOIN 
    movie_companies mc ON dm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    dm.cast_count > 5
ORDER BY 
    dm.production_year DESC, 
    dm.cast_count DESC
LIMIT 10;
