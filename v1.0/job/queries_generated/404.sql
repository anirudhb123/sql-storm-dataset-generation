WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS title_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS num_actors
    FROM 
        aka_title a 
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.num_actors,
        COALESCE(mk.keyword, 'No keyword') AS keyword
    FROM 
        RankedTitles rt
    LEFT JOIN 
        movie_keyword mk ON rt.title = mk.movie_id
    WHERE 
        rt.title_rank <= 5
),
MovieCompanies AS (
    SELECT 
        t.title,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_companies mc ON t.title = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.title
)
SELECT 
    t.title,
    t.production_year,
    t.num_actors,
    COALESCE(t.total_companies, 0) AS total_companies,
    t.companies
FROM 
    TopMovies t
LEFT JOIN 
    MovieCompanies m ON t.title = m.title
WHERE 
    (t.num_actors > 0 AND m.total_companies IS NOT NULL) 
    OR 
    (t.num_actors = 0 AND m.total_companies IS NULL)
ORDER BY 
    t.production_year DESC, 
    t.num_actors DESC;
