WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        AVG(mi.rating) AS avg_rating
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.companies,
        rm.keyword_count,
        rm.avg_rating,
        RANK() OVER (ORDER BY rm.avg_rating DESC, rm.keyword_count DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    tm.title,
    tm.companies,
    tm.keyword_count,
    tm.avg_rating
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.avg_rating DESC;
