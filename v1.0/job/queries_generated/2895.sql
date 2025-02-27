WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(rt.role) AS max_role
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.person_id
),
KeywordMovies AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    tt.title,
    tt.production_year,
    COALESCE(arc.movie_count, 0) AS actor_movie_count,
    COALESCE(km.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(ci.company_names, 'No Companies') AS companies_involved,
    COALESCE(ci.company_types, 'No Company Types') AS types_of_companies
FROM RankedTitles tt
LEFT JOIN ActorRoleCounts arc ON arc.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = tt.title_id)
LEFT JOIN KeywordMovies km ON km.movie_id = tt.title_id
LEFT JOIN CompanyInfo ci ON ci.movie_id = tt.title_id
WHERE tt.rank_per_year <= 5
ORDER BY tt.production_year DESC, tt.title;
