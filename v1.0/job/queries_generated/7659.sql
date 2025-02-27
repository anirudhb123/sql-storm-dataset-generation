WITH MovieRoles AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        c.nr_order AS role_order,
        r.role AS role_name,
        t.production_year,
        c.note AS cast_note
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN title t ON c.movie_id = t.id
    JOIN role_type r ON c.role_id = r.id
    WHERE
        t.production_year >= 2000
        AND a.name IS NOT NULL
),
MovieKeywords AS (
    SELECT
        t.title AS movie_title,
        k.keyword AS associated_keyword
    FROM
        movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE
        k.keyword IS NOT NULL
),
CombinedData AS (
    SELECT
        mr.actor_name,
        mr.movie_title,
        mr.role_order,
        mr.role_name,
        mr.production_year,
        mk.associated_keyword,
        mr.cast_note
    FROM
        MovieRoles mr
    LEFT JOIN MovieKeywords mk ON mr.movie_title = mk.movie_title
)
SELECT 
    actor_name,
    movie_title,
    ARRAY_AGG(DISTINCT associated_keyword) AS keywords,
    MIN(role_order) AS first_role_order,
    MAX(role_order) AS last_role_order,
    COUNT(DISTINCT movie_title) AS total_movies,
    STRING_AGG(DISTINCT cast_note, '; ') AS notes
FROM
    CombinedData
GROUP BY 
    actor_name, movie_title
ORDER BY 
    total_movies DESC, actor_name;
