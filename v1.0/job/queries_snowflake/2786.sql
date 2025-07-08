
WITH MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mt.id, mt.title, mt.production_year
),
CastDetails AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS num_actors,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    GROUP BY ca.movie_id
),
RankedMovies AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        mi.num_companies,
        cd.num_actors,
        cd.actor_names,
        RANK() OVER (PARTITION BY mi.production_year ORDER BY mi.num_companies DESC, cd.num_actors DESC) AS rank_within_year
    FROM MovieInfo mi
    JOIN CastDetails cd ON mi.movie_id = cd.movie_id
)
SELECT 
    rm.production_year,
    rm.title,
    rm.num_companies,
    rm.num_actors,
    rm.actor_names,
    CASE 
        WHEN rm.rank_within_year <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS rank_category
FROM RankedMovies rm
WHERE rm.num_companies IS NOT NULL
AND rm.num_actors > 0
ORDER BY rm.production_year DESC, rm.rank_within_year;
