WITH RankedTitles AS (
    SELECT
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        a.name IS NOT NULL AND t.title IS NOT NULL
),
TitleKeywords AS (
    SELECT
        t.id AS title_id,
        t.title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
FinalOutput AS (
    SELECT
        r.aka_name,
        r.title,
        r.production_year,
        tk.keyword,
        ci.company_name,
        ci.company_type,
        r.rank,
        tk.keyword_rank,
        ci.company_rank
    FROM
        RankedTitles r
    LEFT JOIN
        TitleKeywords tk ON r.title_id = tk.title_id
    LEFT JOIN
        CompanyInfo ci ON r.title_id = ci.movie_id
)
SELECT
    aka_name,
    title,
    production_year,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies,
    COUNT(DISTINCT rank) AS unique_ranks,
    COUNT(DISTINCT keyword_rank) AS unique_keyword_ranks,
    COUNT(DISTINCT company_rank) AS unique_company_ranks
FROM
    FinalOutput
GROUP BY
    aka_name,
    title,
    production_year
ORDER BY
    production_year DESC, aka_name;
