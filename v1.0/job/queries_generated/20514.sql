WITH RankedMovies AS (
    SELECT
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rank
    FROM
        title
    WHERE
        title.production_year IS NOT NULL
),

ActorDetails AS (
    SELECT
        ak.person_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM
        aka_name ak
        INNER JOIN cast_info ci ON ak.person_id = ci.person_id
        INNER JOIN aka_title t ON ci.movie_id = t.movie_id
    GROUP BY
        ak.person_id, ak.name
),

CompanyMovies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        movie_companies mc
        INNER JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),

ActorsRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        ad.actor_name,
        ad.movie_count,
        cm.companies
    FROM 
        RankedMovies rm
        LEFT JOIN ActorDetails ad ON rm.movie_id = ad.movie_id
        LEFT JOIN CompanyMovies cm ON rm.movie_id = cm.movie_id
)

SELECT 
    arm.movie_title,
    arm.production_year,
    COALESCE(arm.actor_name, 'Unknown Actor') AS lead_actor,
    arm.movie_count AS number_of_movies,
    COALESCE(arm.companies, 'No Companies Involved') AS production_companies
FROM 
    ActorsRankedMovies arm
WHERE 
    (arm.production_year > 2000 OR arm.production_year IS NULL)
    AND (arm.movie_count > 5 OR arm.actor_name IS NULL)
ORDER BY 
    arm.production_year DESC, arm.movie_title ASC;
