
WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS starring_roles,
        a.id AS movie_id
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
KeywordDetails AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(co.name, ', ') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
RankedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.total_cast,
        md.starring_roles,
        kd.keywords,
        cd.companies,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.total_cast DESC) AS rank,
        md.movie_id
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordDetails kd ON md.movie_id = kd.movie_id
    LEFT JOIN 
        MovieCompanyDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    r.movie_title,
    r.production_year,
    r.total_cast,
    r.starring_roles,
    r.keywords,
    r.companies
FROM 
    RankedMovies r
WHERE 
    r.total_cast > 5 
    AND r.production_year BETWEEN 2000 AND 2020
ORDER BY 
    r.rank
FETCH FIRST 10 ROWS ONLY;
