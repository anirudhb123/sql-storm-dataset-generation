WITH ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count, 
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name an ON c.person_id = an.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id
),
keyword_details AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title, 
    rm.production_year,
    COALESCE(kd.keywords, 'No Keywords') AS keywords,
    rm.cast_count,
    nt.name AS first_actor,
    nt.surname_pcode
FROM 
    ranked_movies rm
LEFT JOIN 
    keyword_details kd ON rm.id = kd.movie_id
LEFT JOIN 
    complete_cast cc ON rm.id = cc.movie_id
LEFT JOIN 
    aka_name nt ON cc.subject_id = nt.person_id
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC,
    rm.cast_count DESC
FETCH FIRST 10 ROWS ONLY;
