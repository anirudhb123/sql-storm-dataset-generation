WITH MovieDetails AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        AVG(CAST(ci.nr_order AS FLOAT)) AS avg_order,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        md.title, 
        md.production_year, 
        md.avg_order, 
        md.total_cast,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.avg_order DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    tm.title,
    tm.production_year,
    tm.avg_order,
    tm.total_cast,
    COALESCE(cn.name, 'Unknown') AS company_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON tm.title_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    tm.rank <= 5
GROUP BY 
    tm.title, tm.production_year, tm.avg_order, tm.total_cast, cn.name
ORDER BY 
    tm.production_year DESC, tm.avg_order DESC;
