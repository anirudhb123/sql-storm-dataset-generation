WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS movie_rank
    FROM title t
),
DirectorTitles AS (
    SELECT 
        c.movie_id,
        a.name AS director_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS director_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.role_id = (SELECT id FROM role_type WHERE role = 'Director')
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    dt.director_name,
    mk.keywords,
    cd.companies,
    CASE 
        WHEN rm.movie_rank IS NULL THEN 'Rank Not Available'
        ELSE CAST(rm.movie_rank AS TEXT) 
    END AS rank
FROM RankedMovies rm
LEFT JOIN DirectorTitles dt ON rm.movie_id = dt.movie_id
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE rm.production_year > 2000
ORDER BY rm.production_year DESC, rm.title;
