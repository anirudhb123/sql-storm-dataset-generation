WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        ka.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM
        aka_title AS t
    LEFT JOIN
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN
        aka_name AS ka ON c.person_id = ka.person_id
    LEFT JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000 
        AND (t.kind_id IS NULL OR t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Movie'))
),
ActorInfo AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MAX(CASE WHEN p.info_type_id = 1 THEN p.info END) AS birth_date,
        MAX(CASE WHEN p.info_type_id = 2 THEN p.info END) AS death_date
    FROM
        aka_name AS ka
    LEFT JOIN
        cast_info AS c ON ka.person_id = c.person_id
    LEFT JOIN
        person_info AS p ON ka.person_id = p.person_id
    GROUP BY 
        ka.person_id, ka.name
),
MoviesWithHighKeywords AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.actor_name,
        rm.actor_rank,
        ai.movie_count,
        ai.birth_date,
        ai.death_date
    FROM 
        RankedMovies AS rm
    JOIN 
        ActorInfo AS ai ON rm.actor_name = ai.name
    WHERE 
        rm.keyword_count > 5
)
SELECT
    mwh.title,
    mwh.production_year,
    mwh.actor_name,
    mwh.actor_rank,
    mwh.movie_count,
    COALESCE(mwh.birth_date, 'Unknown') AS birth_date,
    COALESCE(mwh.death_date, 'Still Alive') AS death_date,
    CASE 
        WHEN mwh.actor_rank = 1 THEN 'Lead Actor'
        WHEN mwh.actor_rank <= 3 THEN 'Supporting Actor'
        ELSE 'Minor Role'
    END AS role_description
FROM
    MoviesWithHighKeywords AS mwh
ORDER BY
    mwh.production_year DESC, 
    mwh.actor_name ASC;

-- Perform an anti-join to find actors who have not starred in movies with more than 5 keywords
EXCEPT
SELECT
    ka.name
FROM
    aka_name AS ka
JOIN
    cast_info AS ci ON ka.person_id = ci.person_id
GROUP BY 
    ka.person_id, ka.name
HAVING 
    COUNT(DISTINCT ci.movie_id) = 0;
