WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        num_cast_members 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.num_cast_members,
    ci.company_names,
    ci.num_companies,
    COALESCE(SUM(mo.info IS NOT NULL), 0) AS num_movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyInfo ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    movie_info mo ON tm.movie_id = mo.movie_id
GROUP BY 
    tm.movie_id, ci.company_names
ORDER BY 
    tm.production_year DESC, tm.num_cast_members DESC;
