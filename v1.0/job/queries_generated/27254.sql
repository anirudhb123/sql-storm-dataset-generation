WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        GROUP_CONCAT(dISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS cast_members,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name SEPARATOR ', ') AS production_companies
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        cast_info ci ON ci.movie_id = t.id
    JOIN
        aka_name c ON ci.person_id = c.person_id
    JOIN
        movie_companies mc ON mc.movie_id = t.id
    JOIN
        company_name co ON mc.company_id = co.id
    WHERE
        t.production_year BETWEEN 2000 AND 2020
        AND k.keyword LIKE '%action%'
    GROUP BY
        t.id
    HAVING
        COUNT(DISTINCT ci.person_id) >= 5
),
MovieInfoWithRatings AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_members,
        md.production_companies,
        CASE 
            WHEN md.production_year < 2010 THEN 'Classic Action'
            WHEN md.production_year BETWEEN 2010 AND 2015 THEN 'Modern Action'
            ELSE 'Recent Action'
        END AS era
    FROM
        MovieDetails md
)
SELECT
    mi.title,
    mi.production_year,
    mi.cast_members,
    mi.production_companies,
    mi.era,
    COUNT(DISTINCT mi.movie_id) AS movie_count
FROM
    MovieInfoWithRatings mi
GROUP BY
    mi.title, mi.production_year, mi.cast_members, mi.production_companies, mi.era
ORDER BY
    movie_count DESC,
    mi.production_year DESC;
