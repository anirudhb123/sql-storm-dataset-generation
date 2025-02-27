WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY co.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tr.movie_title,
    tr.production_year,
    tr.cast_count,
    ci.company_name,
    ci.company_type
FROM 
    TopRankedMovies tr
LEFT JOIN 
    CompanyInfo ci ON tr.movie_title = ci.movie_id AND ci.company_rank = 1
WHERE 
    tr.cast_count > 0
ORDER BY 
    tr.production_year DESC, tr.cast_count DESC;
