WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank_year
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
FilteredAkaNames AS (
    SELECT
        ak.id AS aka_id,
        ak.name,
        ak.person_id,
        ak.imdb_index
    FROM
        aka_name ak
    WHERE
        ak.name ILIKE '%Smith%' OR ak.name LIKE '%Jon%'
),
SubqueryMovies AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        m.production_year > 2000
    GROUP BY
        m.id
),
CastWithRoles AS (
    SELECT
        c.movie_id,
        c.person_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    INNER JOIN
        role_type r ON c.person_role_id = r.id
),
CompanyAndTitles AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT co.name) AS companies,
        COUNT(mci.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    LEFT JOIN
        movie_info mci ON mc.movie_id = mci.movie_id AND mci.info_type_id = 1
    GROUP BY
        mc.movie_id
)

SELECT
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    fk.name AS Actor_Name,
    ck.role_name AS Role,
    ct.companies AS Production_Companies,
    kt.keywords AS Movie_Keywords,
    CASE 
        WHEN ct.company_count > 1 THEN 'Produced by multiple companies'
        ELSE 'Produced by a single company'
    END AS Company_Production_Info,
    RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS Year_Rank
FROM
    RankedTitles t
LEFT JOIN
    FilteredAkaNames fk ON fk.person_id = (SELECT c.person_id FROM cast_info c WHERE c.movie_id = t.title_id LIMIT 1)
LEFT JOIN
    CastWithRoles ck ON ck.movie_id = t.title_id
LEFT JOIN
    CompanyAndTitles ct ON ct.movie_id = t.title_id
LEFT JOIN
    SubqueryMovies kt ON kt.movie_id = t.title_id
WHERE
    t.rank_year <= 10
    AND (ct.company_count IS NOT NULL AND ct.company_count > 0)
ORDER BY
    t.production_year DESC, t.title;
