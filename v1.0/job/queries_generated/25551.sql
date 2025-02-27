WITH RankedTitles AS (
    SELECT
        at.title AS title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY
        at.title, at.production_year
),
PopularActor AS (
    SELECT
        an.name AS actor_name,
        an.id AS actor_id,
        COUNT(ci.movie_id) AS movies_count
    FROM
        aka_name an
    JOIN
        cast_info ci ON an.person_id = ci.person_id
    GROUP BY
        an.name, an.id
    ORDER BY
        movies_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT
        at.title AS movie_title,
        at.production_year,
        GROUP_CONCAT(DISTINCT an.name ORDER BY an.name) AS actors_list,
        kt.keyword AS movie_keyword
    FROM
        aka_title at
    JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN
        aka_name an ON ci.person_id = an.person_id
    JOIN
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY
        at.title, at.production_year, kt.keyword
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actors_list,
    COUNT(md.movie_keyword) AS keyword_count,
    (SELECT COUNT(*) FROM PopularActor) AS total_popular_actors
FROM
    MovieDetails md
JOIN
    RankedTitles rt ON md.movie_title = rt.title
WHERE
    rt.year_rank <= 5
GROUP BY
    md.movie_title, md.production_year, md.actors_list
ORDER BY
    md.production_year DESC, keyword_count DESC;
