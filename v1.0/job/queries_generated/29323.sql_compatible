
WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title at
        JOIN complete_cast cc ON cc.movie_id = at.movie_id
        JOIN cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
        JOIN aka_name an ON an.person_id = ci.person_id
        LEFT JOIN movie_keyword mk ON mk.movie_id = at.movie_id
        LEFT JOIN keyword kw ON kw.id = mk.keyword_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.id, at.title, at.production_year
),
movie_info_with_notes AS (
    SELECT 
        rm.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_notes
    FROM 
        ranked_movies rm
        LEFT JOIN movie_info mi ON mi.movie_id = rm.movie_id
    GROUP BY 
        rm.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.cast_names,
    COALESCE(miw.info_notes, 'No notes available') AS info_notes
FROM 
    ranked_movies rm
    LEFT JOIN movie_info_with_notes miw ON miw.movie_id = rm.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
