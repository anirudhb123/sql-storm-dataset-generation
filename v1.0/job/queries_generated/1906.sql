WITH RecentMovies AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year
    FROM aka_title mt
    WHERE mt.production_year >= 2020
), 
MovieKeywords AS (
    SELECT mk.movie_id, k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
CompanyDetails AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
ActorRoles AS (
    SELECT ci.movie_id, an.name AS actor_name, rt.role AS role
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),
MovieInfoDetail AS (
    SELECT mi.movie_id, COUNT(DISTINCT mi.info_type_id) AS info_types_count
    FROM movie_info mi
    GROUP BY mi.movie_id
),
RankedMovies AS (
    SELECT rm.movie_id, ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.title) AS rank
    FROM RecentMovies rm
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.company_name, 'No Company') AS company_name,
    COALESCE(cd.company_type, 'Unknown Type') AS company_type,
    ar.actor_name,
    ar.role,
    mid.info_types_count
FROM RankedMovies rm
LEFT JOIN (SELECT movie_id, STRING_AGG(keyword, ', ') AS keywords FROM MovieKeywords GROUP BY movie_id) k ON rm.movie_id = k.movie_id
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN MovieInfoDetail mid ON rm.movie_id = mid.movie_id
WHERE rm.rank <= 5
ORDER BY rm.production_year DESC, rm.title;
