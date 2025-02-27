WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS main_cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY a.production_year DESC, a.title) AS rank
    FROM 
        aka_title a
    INNER JOIN 
        complete_cast cc ON a.id = cc.movie_id
    INNER JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    INNER JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id
)

SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.main_cast_names,
    rm.keywords
FROM 
    RankedMovies rm
WHERE 
    rm.cast_count > 5
ORDER BY 
    rm.production_year DESC, rm.title;
