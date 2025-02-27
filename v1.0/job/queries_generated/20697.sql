WITH MovieRoles AS (
    SELECT
        c.movie_id,
        a.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        a.name IS NOT NULL
),
MovieTitles AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cp.kind AS company_type,
        COUNT(DISTINCT c.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cp ON mc.company_id = cp.id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, cp.kind
)
SELECT
    mt.movie_id,
    mt.title,
    mt.production_year,
    mr.person_id AS lead_actor_id,
    a.name AS lead_actor_name,
    CASE WHEN cd.company_count > 1 THEN 'Multiple Companies' ELSE cd.company_type END AS company_info,
    COUNT(DISTINCT mv.linked_movie_id) AS linked_movies,
    STRING_AGG(DISTINCT mt.keyword, ', ') AS keywords
FROM
    MovieTitles mt
LEFT JOIN
    MovieRoles mr ON mt.movie_id = mr.movie_id AND mr.role_rank = 1 
LEFT JOIN
    aka_name a ON mr.person_id = a.person_id
LEFT JOIN
    CompanyDetails cd ON mt.movie_id = cd.movie_id
LEFT JOIN
    movie_link mv ON mt.movie_id = mv.movie_id
GROUP BY
    mt.movie_id, mt.title, mt.production_year, mr.person_id, a.name, cd.company_count, cd.company_type
HAVING
    COUNT(DISTINCT mv.linked_movie_id) > 0 OR cd.company_count IS NULL
ORDER BY
    mt.production_year DESC, mt.title ASC;
