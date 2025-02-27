WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        complete_cast c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
    HAVING 
        COUNT(c.id) > 2
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    ci.company_names,
    (SELECT COUNT(DISTINCT ki.keyword) 
     FROM movie_keyword mk 
     JOIN keyword ki ON mk.keyword_id = ki.id 
     WHERE mk.movie_id = tm.movie_id) AS keyword_count,
    (CASE 
        WHEN tm.production_year < 2000 THEN 'Classic' 
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern' 
        ELSE 'Recent' 
    END) AS era
FROM 
    TopRatedMovies tm
LEFT JOIN 
    CompanyInfo ci ON tm.movie_id = ci.movie_id
WHERE 
    tm.rank_per_year <= 5
ORDER BY 
    tm.production_year DESC, tm.title ASC;
