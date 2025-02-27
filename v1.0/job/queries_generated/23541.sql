WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        rk.rank,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS num_movies
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        (SELECT 
            title_id, 
            COUNT(*) AS rank
        FROM 
            movie_info
        WHERE 
            LOWER(info) LIKE '%award%'
        GROUP BY 
            title_id) rk ON mt.id = rk.title_id
    WHERE 
        mt.production_year IS NOT NULL
    AND 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),

ActorRoles AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS null_order_count,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS valid_role_count
    FROM
        cast_info ci
    JOIN
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
),

EnhancedRoleData AS (
    SELECT
        ar.person_id,
        ar.movie_count,
        ar.null_order_count,
        ar.valid_role_count,
        (SELECT COUNT(*) FROM char_name cn WHERE cn.imdb_index IS NOT NULL) AS distinct_char_count
    FROM 
        ActorRoles ar
    WHERE 
        ar.movie_count > 5
)

SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.year_rank,
    ar.movie_count AS actor_movie_count,
    ar.null_order_count AS actor_null_order_count,
    ar.valid_role_count AS actor_valid_role_count,
    COALESCE(NULLIF(LEFT(mt.note, 30), ''), 'No Note Available') AS movie_note
FROM
    RankedMovies rm
JOIN
    movie_info mi ON rm.movie_id = mi.movie_id
LEFT JOIN
    EnhancedRoleData ar ON mi.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ar.person_id)
WHERE
    rm.num_movies > 1
ORDER BY 
    rm.production_year DESC, 
    rm.year_rank, 
    ar.movie_count DESC;
