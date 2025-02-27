WITH RankedMovies AS (
    SELECT
        M.id AS movie_id,
        M.title,
        M.production_year,
        ROW_NUMBER() OVER (PARTITION BY M.production_year ORDER BY M.title) AS title_rank,
        COUNT(CASE WHEN K.keyword IS NOT NULL THEN 1 END) OVER (PARTITION BY M.id) AS keyword_count
    FROM
        aka_title M
    LEFT JOIN
        movie_keyword MK ON M.id = MK.movie_id
    LEFT JOIN
        keyword K ON MK.keyword_id = K.id
), 
ActorInfo AS (
    SELECT
        A.id AS actor_id,
        A.name,
        COUNT(DISTINCT C.movie_id) AS num_movies,
        MAX(CASE WHEN C.nr_order IS NOT NULL THEN C.nr_order ELSE 0 END) AS max_order,
        STRING_AGG(DISTINCT COALESCE(K.keyword, 'Unspecified'), ', ') AS keywords
    FROM
        aka_name A
    LEFT JOIN
        cast_info C ON A.person_id = C.person_id
    LEFT JOIN 
        movie_keyword MK ON C.movie_id = MK.movie_id
    LEFT JOIN 
        keyword K ON MK.keyword_id = K.id
    WHERE
        A.name IS NOT NULL
    GROUP BY
        A.id, A.name
), 
MovieCompanies AS (
    SELECT
        MC.movie_id,
        STRING_AGG(DISTINCT COALESCE(CN.name, 'Unknown Company'), '; ') AS companies,
        STRING_AGG(DISTINCT COALESCE(CT.kind, 'Unknown Type'), ', ') AS types
    FROM
        movie_companies MC
    LEFT JOIN
        company_name CN ON MC.company_id = CN.id
    LEFT JOIN
        company_type CT ON MC.company_type_id = CT.id
    GROUP BY
        MC.movie_id
), 
MoviesWithActors AS (
    SELECT
        RM.movie_id,
        RM.title,
        RM.production_year,
        AI.actor_id,
        AI.name AS actor_name,
        AI.num_movies,
        AI.max_order,
        AI.keywords,
        MC.companies,
        MC.types,
        RM.keyword_count
    FROM
        RankedMovies RM
    LEFT JOIN
        cast_info CI ON RM.movie_id = CI.movie_id
    LEFT JOIN
        ActorInfo AI ON CI.person_id = AI.actor_id
    LEFT JOIN
        MovieCompanies MC ON RM.movie_id = MC.movie_id
)
SELECT
    M.title,
    M.production_year,
    M.actor_name,
    M.num_movies,
    M.max_order,
    CASE 
        WHEN M.keyword_count > 0 THEN M.keywords
        ELSE 'No Keywords Available'
    END AS keywords_info,
    CASE 
        WHEN M.companies IS NOT NULL THEN M.companies
        ELSE 'No Companies Listed'
    END AS company_info,
    M.types AS company_types
FROM
    MoviesWithActors M
WHERE
    M.production_year >= 2000
    AND (M.num_movies > 5 OR M.max_order > 3)
ORDER BY
    M.production_year DESC, M.title ASC 
LIMIT 50;
