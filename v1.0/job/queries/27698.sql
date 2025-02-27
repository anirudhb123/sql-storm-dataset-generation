WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(mo.info_length) AS average_info_length
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            LENGTH(info) AS info_length 
         FROM 
            movie_info) mo ON a.id = mo.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
), 
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        company_count,
        keyword_count,
        average_info_length,
        RANK() OVER (ORDER BY company_count DESC, keyword_count DESC, average_info_length DESC) AS movie_rank
    FROM 
        RankedMovies
)
SELECT 
    r.title,
    r.production_year,
    r.kind_id,
    r.company_count,
    r.keyword_count,
    r.average_info_length
FROM 
    TopRankedMovies r
WHERE 
    r.movie_rank <= 10
ORDER BY 
    r.movie_rank;
