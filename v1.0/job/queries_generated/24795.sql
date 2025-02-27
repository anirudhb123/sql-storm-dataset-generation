WITH
    RankedMovies AS (
        SELECT
            mt.id AS movie_id,
            mt.title,
            mt.production_year,
            RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS production_rank
        FROM
            aka_title mt
        WHERE
            mt.production_year IS NOT NULL
    ),
    CastDetails AS (
        SELECT
            ci.movie_id,
            ci.person_id,
            ak.name AS actor_name,
            ci.role_id,
            COALESCE(rt.role, 'Unknown') AS role_description,
            COUNT(ci.nr_order) OVER (PARTITION BY ci.movie_id) AS cast_count
        FROM
            cast_info ci
        JOIN
            aka_name ak ON ci.person_id = ak.person_id
        LEFT JOIN
            role_type rt ON ci.role_id = rt.id
    ),
    MovieKeywords AS (
        SELECT
            mk.movie_id,
            GROUP_CONCAT(mk.keyword) AS keywords
        FROM
            movie_keyword mk
        JOIN
            keyword k ON mk.keyword_id = k.id
        GROUP BY
            mk.movie_id
    ),
    MovieCompany AS (
        SELECT
            mc.movie_id,
            STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM
            movie_companies mc
        JOIN
            company_name cn ON mc.company_id = cn.id
        WHERE
            cn.country_code IS NOT NULL
        GROUP BY
            mc.movie_id
    )
SELECT
    rm.title AS movie_title,
    rm.production_year,
    cd.actor_name,
    cd.role_description,
    cd.cast_count,
    COALESCE(mk.keywords, 'None') AS keywords,
    mc.company_names,
    mc.company_count,
    SUM(CASE WHEN cd.role_description = 'Director' THEN 1 ELSE 0 END) 
       OVER (PARTITION BY rm.production_year) AS director_count_by_year,
    COUNT(DISTINCT ci.id) AS total_cast,
    CASE 
        WHEN COUNT(DISTINCT ci.id) IS NULL THEN 'No Cast' 
        ELSE 'Has Cast' 
    END AS cast_status
FROM
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompany mc ON rm.movie_id = mc.movie_id
GROUP BY
    rm.movie_id, rm.title, rm.production_year, cd.actor_name, cd.role_description, mk.keywords, mc.company_names, mc.company_count
HAVING
    ARRAY_LENGTH(ARRAY_AGG(DISTINCT cd.role_id), 1) > 1
ORDER BY
    rm.production_year DESC, rm.title ASC;
