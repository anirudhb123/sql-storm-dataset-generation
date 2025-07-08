
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
MovieActors AS (
    SELECT 
        t.id AS title_id,
        a.name AS actor_name,
        COUNT(ci.id) AS role_count
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN title t ON ci.movie_id = t.id
    GROUP BY t.id, a.name
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE c.country_code IS NOT NULL
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    ma.actor_name,
    COALESCE(cm.company_name, 'No Company') AS company_name,
    COALESCE(ki.keywords, 'No Keywords') AS keywords,
    ma.role_count
FROM RankedMovies rm
LEFT JOIN MovieActors ma ON rm.title_id = ma.title_id
LEFT JOIN CompanyMovies cm ON rm.title_id = cm.movie_id
LEFT JOIN KeywordInfo ki ON rm.title_id = ki.movie_id
WHERE rm.year_rank < 5
ORDER BY rm.production_year DESC, ma.role_count DESC NULLS LAST;
