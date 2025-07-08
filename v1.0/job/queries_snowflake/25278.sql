
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.title, 
        a.production_year, 
        a.kind_id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        kind_id,
        company_count,
        keyword_count,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10
)

SELECT 
    tm.title,
    tm.production_year,
    kt.kind AS kind_description,
    tm.company_count,
    tm.keyword_count,
    tm.cast_count,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM 
    TopMovies tm
JOIN 
    kind_type kt ON tm.kind_id = kt.id
LEFT JOIN 
    movie_companies mc ON tm.kind_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON tm.kind_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    tm.title, 
    tm.production_year, 
    kt.kind, 
    tm.company_count, 
    tm.keyword_count, 
    tm.cast_count
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
