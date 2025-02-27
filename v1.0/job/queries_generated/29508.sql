WITH RecursiveCast AS (
    SELECT
        ci.person_id,
        a.title AS movie_title,
        a.production_year,
        ARRAY_AGG(DISTINCT rc.role_id) AS roles
    FROM
        cast_info ci
    JOIN
        aka_title a ON ci.movie_id = a.id
    LEFT JOIN 
        role_type rc ON ci.person_role_id = rc.id
    WHERE
        a.production_year >= 2000
    GROUP BY
        ci.person_id, a.title, a.production_year
),
TopActors AS (
    SELECT
        person_id,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM
        RecursiveCast
    GROUP BY
        person_id
    ORDER BY
        movie_count DESC
    LIMIT 10
),
ActorDetails AS (
    SELECT
        pa.person_id,
        ak.name,
        ak.name_pcode_cf,
        ak.name_pcode_nf,
        ta.movie_count
    FROM
        TopActors ta
    JOIN
        aka_name ak ON ta.person_id = ak.person_id
    JOIN
        name pn ON ta.person_id = pn.imdb_id
)
SELECT
    ad.name AS actor_name,
    ad.name_pcode_cf,
    ad.name_pcode_nf,
    ad.movie_count,
    STRING_AGG(DISTINCT rc.movie_title || ' (' || rc.production_year || ')', ', ') AS movies
FROM
    ActorDetails ad
JOIN
    RecursiveCast rc ON ad.person_id = rc.person_id
GROUP BY
    ad.name, ad.name_pcode_cf, ad.name_pcode_nf, ad.movie_count
ORDER BY
    ad.movie_count DESC;
