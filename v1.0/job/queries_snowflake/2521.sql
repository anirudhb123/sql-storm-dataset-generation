
WITH RecentMovies AS (
    SELECT 
        at.title,
        at.production_year,
        at.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_title at
    WHERE 
        at.production_year >= 2020
), 
TopActors AS (
    SELECT 
        ak.name,
        COUNT(ci.movie_id) AS num_movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
), 
ActorRoles AS (
    SELECT 
        ak.name,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.nr_order < 5
    GROUP BY 
        ak.name, rt.role
), 
MovieCompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ta.num_movies, 0) AS actor_movie_count,
    COALESCE(ar.role_count, 0) AS role_count,
    COALESCE(mcc.company_count, 0) AS movie_company_count
FROM 
    RecentMovies rm
LEFT JOIN 
    TopActors ta ON ta.name IN (SELECT ak.name FROM aka_name ak JOIN cast_info ci ON ak.person_id = ci.person_id AND ci.movie_id = rm.movie_id)
LEFT JOIN 
    ActorRoles ar ON ar.name = (SELECT ak.name FROM aka_name ak JOIN cast_info ci ON ak.person_id = ci.person_id AND ci.movie_id = rm.movie_id LIMIT 1)
LEFT JOIN 
    MovieCompanyCounts mcc ON mcc.movie_id = rm.movie_id
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
