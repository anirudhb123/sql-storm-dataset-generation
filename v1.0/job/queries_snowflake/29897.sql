
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY mt.production_year DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.aka_names,
    rm.company_names,
    rm.keywords,
    rm.cast_count,
    rm.rank,
    (SELECT COUNT(*) FROM RankedMovies) AS total_movies
FROM 
    RankedMovies rm
WHERE 
    rm.cast_count > 5
ORDER BY 
    rm.rank;
