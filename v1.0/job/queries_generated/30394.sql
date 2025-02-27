WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        0 AS level,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000 -- Filtering for movies produced from 2000 onwards
    UNION ALL
    SELECT
        ml.linked_movie_id,
        mh.level + 1,
        at.title,
        at.production_year,
        at.kind_id,
        at.episode_of_id
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN
        aka_title at ON at.id = ml.linked_movie_id
)

SELECT
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    mh.level AS Link_Level,
    COUNT(mc.company_id) FILTER (WHERE mc.company_type_id = 1) AS Production_Companies,
    AVG(pi.info IS NOT NULL)::int AS Has_Info,
    STRING_AGG(DISTINCT ak.name, ', ') AS Actor_Names
FROM
    MovieHierarchy mh
LEFT JOIN
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN
    person_info pi ON pi.person_id = ci.person_id
WHERE
    mh.level <= 2 -- Including only direct and one-level linked movies
    AND mh.episode_of_id IS NULL -- Exclude episodes
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY
    mh.production_year DESC, Movie_Title;
