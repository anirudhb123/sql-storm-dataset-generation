WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
        JOIN cast_info c ON a.person_id = c.person_id
        JOIN aka_title t ON c.movie_id = t.movie_id
),
PersonDetails AS (
    SELECT 
        a.person_id,
        a.name AS person_name,
        p.info AS additional_info,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY p.note) AS info_rank
    FROM 
        aka_name a
        LEFT JOIN person_info p ON a.person_id = p.person_id
),
MovieKeywordSummary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
        JOIN keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    pd.person_id,
    pd.person_name,
    rt.movie_title,
    rt.production_year,
    CASE 
        WHEN rt.title_rank = 1 THEN 'Latest Release'
        ELSE 'Previous Release'
    END AS release_status,
    mks.keywords
FROM 
    RankedTitles rt
    JOIN PersonDetails pd ON rt.aka_id = pd.aka_id
    LEFT JOIN MovieKeywordSummary mks ON rt.aka_id = mks.movie_id
WHERE 
    rt.title_rank <= 3 AND pd.info_rank = 1
ORDER BY 
    pd.person_name, rt.production_year DESC;

