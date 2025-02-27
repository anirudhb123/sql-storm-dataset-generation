WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
RecursiveTitleLinks AS (
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        1 AS link_depth
    FROM
        movie_link ml
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Also known as')

    UNION ALL

    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        rtl.link_depth + 1
    FROM 
        movie_link ml
    JOIN 
        RecursiveTitleLinks rtl ON ml.movie_id = rtl.linked_movie_id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Also known as')
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.country_code) AS rn
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT 
    tt.title_id,
    tt.title,
    tt.production_year,
    CASE 
        WHEN rc.link_depth > 1 THEN 'Linked Movie'
        ELSE 'Original Movie'
    END AS movie_relationship,
    mc.company_name,
    mc.company_type,
    mk.keywords
FROM 
    RankedMovies tt
LEFT JOIN 
    RecursiveTitleLinks rc ON tt.title_id = rc.movie_id
LEFT JOIN 
    MovieCompanies mc ON tt.title_id = mc.movie_id AND mc.rn = 1
LEFT JOIN 
    MovieKeywords mk ON tt.title_id = mk.movie_id
WHERE 
    tt.rn <= 10
ORDER BY 
    tt.production_year DESC, 
    tt.title;
