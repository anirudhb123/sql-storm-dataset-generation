WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
),
ActorInfo AS (
    SELECT
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FilteredMovies AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = r.title_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')) AS budget_count,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = r.title_id) AS keyword_count
    FROM 
        RankedMovies r
    WHERE 
        r.production_year > 2000
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(c.company_name, 'No Company') AS production_company,
    a.name AS actor_name,
    a.movie_count,
    f.budget_count,
    f.keyword_count
FROM 
    FilteredMovies f
LEFT JOIN 
    CompanyMovies c ON f.title_id = c.movie_id
LEFT JOIN 
    ActorInfo a ON a.movie_count > 5
WHERE 
    f.budget_count > 0
ORDER BY 
    f.production_year DESC, f.title;
