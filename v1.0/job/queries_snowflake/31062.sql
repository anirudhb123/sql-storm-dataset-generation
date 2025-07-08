
WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        a.name LIKE 'A%'
),
MoviesWithKeywords AS (
    SELECT
        mt.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY
        mt.movie_id
),
CompanyCast AS (
    SELECT
        mc.movie_id,
        co.name AS company_name,
        c.person_id,
        r.role AS role_name
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        cast_info c ON mc.movie_id = c.movie_id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        co.country_code = 'USA'
),
MovieInfoCTE AS (
    SELECT
        mi.movie_id,
        COUNT(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot') THEN 1 END) AS plot_count,
        LISTAGG(mi.info || ' (' || it.info || ')', '; ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)
SELECT
    at.title,
    at.production_year,
    k.keywords,
    ca.company_name,
    mi.info_details,
    ah.role_order
FROM
    aka_title at
LEFT JOIN
    MoviesWithKeywords k ON at.id = k.movie_id
LEFT JOIN
    CompanyCast ca ON at.id = ca.movie_id
LEFT JOIN
    MovieInfoCTE mi ON at.id = mi.movie_id
LEFT JOIN
    ActorHierarchy ah ON at.id = ah.movie_id
WHERE
    at.production_year >= 2000
    AND (k.keywords IS NULL OR ARRAY_CONTAINS(k.keywords, 'Action'))
ORDER BY
    at.production_year DESC,
    ah.role_order ASC NULLS LAST;
