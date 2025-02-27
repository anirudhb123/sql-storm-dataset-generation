WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
PopularMovies AS (
    SELECT 
        movie_title,
        production_year,
        CAST(rank AS integer) AS movie_rank
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    pm.movie_title,
    pm.production_year,
    pm.movie_rank,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT mw.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    PopularMovies pm
LEFT JOIN 
    movie_companies mc ON pm.movie_title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    movie_keyword mw ON pm.movie_title = (SELECT title FROM aka_title WHERE id = mw.movie_id)
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
GROUP BY 
    pm.movie_title, pm.production_year, pm.movie_rank
ORDER BY 
    pm.movie_rank;
