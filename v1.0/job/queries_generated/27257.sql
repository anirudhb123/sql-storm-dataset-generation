WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT ch.name, ', ') AS char_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT kw.keyword) AS keywords_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title ASC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON mt.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        char_name ch ON ak.id = ch.imdb_id
    GROUP BY 
        mt.id
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.aka_names,
    rm.char_names,
    rm.company_count,
    rm.keywords_count
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title ASC;
