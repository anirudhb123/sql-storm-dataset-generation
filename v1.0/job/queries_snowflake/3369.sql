
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
FilteredTitles AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        cd.company_names,
        cd.company_types,
        km.keyword_count
    FROM RankedMovies rm
    LEFT JOIN CompanyDetails cd ON rm.title_id = cd.movie_id
    LEFT JOIN KeywordMovies km ON rm.title_id = km.movie_id
    WHERE rm.rank <= 5 AND (rm.actor_count > 0 OR cd.company_names IS NOT NULL)
)
SELECT 
    ft.title,
    ft.production_year,
    ft.actor_count,
    COALESCE(ft.company_names, 'N/A') AS companies,
    COALESCE(ft.company_types, 'N/A') AS types,
    COALESCE(ft.keyword_count, 0) AS keywords
FROM FilteredTitles ft
ORDER BY ft.production_year DESC, ft.actor_count DESC
LIMIT 10;
