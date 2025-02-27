WITH MovieDetails AS (
    SELECT 
        a.id AS alias_id,
        a.name AS alias_name,
        t.title,
        t.production_year,
        c.nr_order,
        p.info AS person_info,
        k.keyword
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN
        person_info p ON a.person_id = p.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
FinalResults AS (
    SELECT
        md.alias_name,
        md.title,
        md.production_year,
        md.nr_order,
        cd.company_name,
        cd.company_type,
        STRING_AGG(DISTINCT md.keyword, ', ') AS keywords
    FROM
        MovieDetails md
    LEFT JOIN
        CompanyDetails cd ON md.alias_id = cd.movie_id
    GROUP BY
        md.alias_name, md.title, md.production_year, md.nr_order, cd.company_name, cd.company_type
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY title ORDER BY production_year DESC) AS ranking
FROM
    FinalResults
ORDER BY
    production_year DESC, alias_name;
