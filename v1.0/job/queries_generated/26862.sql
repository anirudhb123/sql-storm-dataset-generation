WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name SEPARATOR ', ') AS production_companies,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN
        company_name co ON mc.company_id = co.id
    LEFT JOIN
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        aka_name ak ON t.id = ak.person_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id, t.title, t.production_year
),
PersonCasting AS (
    SELECT
        c.movie_id,
        GROUP_CONCAT(DISTINCT p.name ORDER BY p.name SEPARATOR ', ') AS cast_names,
        GROUP_CONCAT(DISTINCT r.role ORDER BY r.role SEPARATOR ', ') AS roles
    FROM
        cast_info c
    INNER JOIN
        name p ON c.person_id = p.imdb_id
    LEFT JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    pc.cast_names,
    pc.roles,
    md.production_companies,
    md.keywords
FROM 
    MovieDetails md
LEFT JOIN 
    PersonCasting pc ON md.movie_id = pc.movie_id
ORDER BY
    md.production_year DESC, md.title ASC;
