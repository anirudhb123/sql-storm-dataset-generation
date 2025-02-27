
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT
        a.id AS actor_id,
        a.name,
        ci.movie_id,
        ci.role_id,
        ci.note AS actor_note,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(c.name || ' (' || ct.kind || ')', ', ') AS companies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CombinedDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ad.actor_id,
        ad.name AS actor_name,
        ad.actor_note,
        mc.companies,
        mk.keywords,
        ad.actor_rank
    FROM RankedMovies rm
    LEFT JOIN ActorDetails ad ON rm.movie_id = ad.movie_id
    LEFT JOIN MovieCompanyDetails mc ON rm.movie_id = mc.movie_id
    LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    cd.actor_name,
    cd.actor_note,
    cd.companies,
    COALESCE(cd.keywords, ARRAY[]::text[]) AS keywords,
    CASE
        WHEN cd.actor_rank IS NULL THEN 'Not in Cast'
        ELSE 'In Cast'
    END AS cast_status
FROM CombinedDetails cd
WHERE 
    (cd.production_year BETWEEN 2000 AND 2023) 
    AND (cd.companies IS NOT NULL OR EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = cd.movie_id AND mi.info LIKE '%Award%'))
ORDER BY cd.production_year DESC, cd.movie_id ASC;
