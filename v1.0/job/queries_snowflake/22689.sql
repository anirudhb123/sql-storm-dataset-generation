
WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY MAX(ci.nr_order) DESC) AS rank
    FROM
        aka_title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
CompanyCount AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
KeywordCount AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CriticalTitles AS (
    SELECT
        r.title_id,
        r.title,
        r.production_year,
        COALESCE(cc.company_count, 0) AS company_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN COALESCE(cc.company_count, 0) > 0 AND COALESCE(kc.keyword_count, 0) > 0 THEN 'Highly Rated'
            WHEN COALESCE(cc.company_count, 0) = 0 AND COALESCE(kc.keyword_count, 0) = 0 THEN 'Non-Notable'
            ELSE 'Noteworthy'
        END AS critical_status,
        r.rank
    FROM
        RankedMovies r
    LEFT JOIN
        CompanyCount cc ON r.title_id = cc.movie_id
    LEFT JOIN
        KeywordCount kc ON r.title_id = kc.movie_id
)
SELECT 
    ct.title,
    ct.production_year,
    ct.company_count,
    ct.keyword_count,
    ct.critical_status,
    n.name AS main_actor_name
FROM 
    CriticalTitles ct
LEFT JOIN 
    cast_info ci ON ct.title_id = ci.movie_id AND ci.nr_order = 1
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
WHERE 
    ct.rank <= 5
    AND (LOWER(n.name) LIKE '%smith%' OR n.name IS NULL)
ORDER BY 
    ct.production_year DESC, ct.title ASC;
