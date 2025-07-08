
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ca.person_id) DESC, mt.production_year DESC) AS movie_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ca ON mt.movie_id = ca.movie_id
    LEFT JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        mt.production_year >= 2000
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    LISTAGG(DISTINCT rt.role, ', ') WITHIN GROUP (ORDER BY rt.role) AS roles,
    LISTAGG(DISTINCT company.name, ', ') WITHIN GROUP (ORDER BY company.name) AS production_companies
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name company ON mc.company_id = company.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.cast_names
ORDER BY 
    tm.production_year DESC;
