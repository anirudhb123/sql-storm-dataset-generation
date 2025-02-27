WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM aka_title mt
    JOIN cast_info ci ON mt.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY mt.id, mt.title, mt.production_year
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON mc.movie_id = mk.movie_id
    GROUP BY mc.movie_id, c.name, ct.kind
)
SELECT
    rm.title,
    rm.production_year,
    rm.actor_names,
    COALESCE(cd.company_name, 'Unknown Company') AS company_name,
    COALESCE(cd.company_type, 'Unknown Type') AS company_type,
    COALESCE(cd.keyword_count, 0) AS keyword_count
FROM RankedMovies rm
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE rm.rank <= 5
ORDER BY rm.production_year DESC, rm.rank ASC;
