WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
movie_cast AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mc.movie_id
),
movies_with_info AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.total_cast,
        COALESCE(mi.info, 'No description available') AS movie_info
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_cast mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
    WHERE 
        rm.year_rank <= 10
)
SELECT 
    mw.title,
    mw.production_year,
    mw.total_cast,
    mw.movie_info,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    movies_with_info mw
LEFT JOIN 
    movie_keyword mk ON mw.movie_id = mk.movie_id
GROUP BY 
    mw.title, mw.production_year, mw.total_cast, mw.movie_info
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
ORDER BY 
    mw.production_year DESC, mw.total_cast DESC;
