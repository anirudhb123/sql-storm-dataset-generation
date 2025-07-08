
WITH MovieInfo AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(CASE WHEN mi.info_type_id = 2 THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.title, mt.production_year
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_count,
        avg_info_length,
        RANK() OVER (ORDER BY company_count DESC, avg_info_length DESC) AS rank
    FROM 
        MovieInfo
),
TopMovies AS (
    SELECT 
        *,
        CASE 
            WHEN production_year = 2020 THEN 'Recent'
            WHEN production_year > 2010 THEN 'Mid-Term'
            ELSE 'Classic'
        END AS movie_classification
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.company_count,
    tm.avg_info_length,
    tm.movie_classification,
    ak.name AS actor_name,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_title = (SELECT title FROM aka_title WHERE id = cc.movie_id LIMIT 1)
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON ak.id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = cc.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
WHERE  
    ak.name IS NOT NULL
GROUP BY 
    tm.movie_title, tm.production_year, tm.company_count, tm.avg_info_length, tm.movie_classification, ak.name
ORDER BY 
    tm.production_year DESC, tm.movie_title;
