WITH actor_movie_counts AS (
    SELECT
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY
        ak.name
),
top_actors AS (
    SELECT
        actor_name,
        movie_count
    FROM
        actor_movie_counts
    ORDER BY
        movie_count DESC
    LIMIT 10
),
actor_details AS (
    SELECT
        ta.actor_name,
        GROUP_CONCAT(DISTINCT ti.title ORDER BY ti.production_year DESC) AS movie_titles,
        MAX(tm.production_year) AS latest_movie_year
    FROM
        top_actors ta
    JOIN
        cast_info ci ON ci.person_id = (SELECT person_id FROM aka_name WHERE name = ta.actor_name) 
    JOIN
        title ti ON ci.movie_id = ti.id
    JOIN
        movie_info mi ON ti.id = mi.movie_id
    JOIN
        movie_keyword mk ON ti.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON ti.id = mc.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ti.production_year >= 2000 
    GROUP BY
        ta.actor_name
)
SELECT
    ad.actor_name,
    ad.movie_titles,
    ad.latest_movie_year
FROM
    actor_details ad
ORDER BY
    ad.latest_movie_year DESC;
