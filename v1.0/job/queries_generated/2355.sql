WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_count_rank
    FROM title m
    LEFT JOIN complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE m.production_year IS NOT NULL
    GROUP BY m.id, m.title, m.production_year
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        a.person_id AS person_id,
        COALESCE(p.info, 'N/A') AS actor_info
    FROM aka_name a
    LEFT JOIN person_info p ON a.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(cc.id) AS total_movies
    FROM movie_companies mc 
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    ad.actor_name,
    ad.actor_info,
    cd.company_name,
    cd.company_type
FROM RankedMovies rm
LEFT JOIN ActorDetails ad ON rm.movie_id = ad.actor_id
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE rm.actor_count_rank <= 5
ORDER BY rm.production_year DESC, rm.movie_title ASC
LIMIT 100;
