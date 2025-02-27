
WITH MovieInformation AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    GROUP BY t.id, t.title, t.production_year, t.kind_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT a.name || ' as ' || rt.role) AS cast_names,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
),
RankedMovies AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        mi.keywords,
        COALESCE(cd.cast_names, ARRAY[]::text[]) AS cast_names,
        mi.company_count,
        ROW_NUMBER() OVER (PARTITION BY mi.production_year ORDER BY mi.company_count DESC) AS rn
    FROM MovieInformation mi
    LEFT JOIN CastDetails cd ON mi.movie_id = cd.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.cast_names,
    rm.company_count
FROM RankedMovies rm
WHERE rm.rn <= 5
    AND rm.production_year IS NOT NULL
ORDER BY rm.production_year, rm.company_count DESC;
