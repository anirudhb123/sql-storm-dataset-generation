WITH MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        p.gender AS actor_gender,
        CASE 
            WHEN p.gender = 'M' THEN 'Male Actor'
            WHEN p.gender = 'F' THEN 'Female Actor'
            ELSE 'Unknown Gender'
        END AS actor_type
    FROM
        title m
    JOIN
        movie_keyword mk ON m.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        cast_info c ON m.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        name p ON p.id = a.person_id
    WHERE
        m.production_year BETWEEN 2000 AND 2020
),
AggregatedResults AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT actor_name, ', ') AS actor_names,
        MAX(CASE WHEN actor_gender = 'M' THEN 1 ELSE 0 END) AS has_male_actor,
        MAX(CASE WHEN actor_gender = 'F' THEN 1 ELSE 0 END) AS has_female_actor
    FROM
        MovieDetails
    GROUP BY
        movie_id, movie_title, production_year, movie_keyword
)
SELECT
    movie_id,
    movie_title,
    production_year,
    movie_keyword,
    actor_count,
    actor_names,
    CASE 
        WHEN has_male_actor = 1 AND has_female_actor = 1 THEN 'Both Genders'
        WHEN has_male_actor = 1 THEN 'Male Only'
        WHEN has_female_actor = 1 THEN 'Female Only'
        ELSE 'No Actors'
    END AS gender_diversity
FROM
    AggregatedResults
ORDER BY
    production_year DESC,
    actor_count DESC;
