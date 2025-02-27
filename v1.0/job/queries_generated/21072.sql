WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        rm.movie_id,
        rm.title AS movie_title,
        rm.production_year
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN RankedMovies rm ON ci.movie_id = rm.movie_id
    WHERE ak.md5sum IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_companies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, company_name, company_type
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT 
    am.actor_id,
    am.actor_name,
    am.movie_title,
    am.production_year,
    COALESCE(mk.keywords, 'No keywords available') AS keywords,
    COALESCE(mc.company_name, 'No companies') AS company_name,
    COALESCE(mc.company_type, 'Unknown type') AS company_type,
    COALESCE(mi.info_details, 'No additional info') AS additional_info
FROM ActorMovies am
LEFT JOIN MovieKeywords mk ON am.movie_id = mk.movie_id
LEFT JOIN MovieCompanies mc ON am.movie_id = mc.movie_id
LEFT JOIN MovieInfo mi ON am.movie_id = mi.movie_id
WHERE am.production_year >= 2000
    AND (am.actor_name IS NOT NULL OR mk.keywords IS NOT NULL)
    AND (am.movie_title LIKE '%The%' OR am.movie_title IS NULL)
ORDER BY am.actor_name, am.production_year DESC, am.movie_title;
