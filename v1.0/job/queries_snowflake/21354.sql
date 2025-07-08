WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON mt.movie_id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_kind,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id 
),
KeyWordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.total_cast,
    ci.company_name,
    ci.company_kind,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic Era'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern Era'
        ELSE 'Recent Era'
    END AS era,
    CASE 
        WHEN m.note_count > 0 THEN 'Has Notes'
        ELSE 'No Notes'
    END AS note_status
FROM 
    MovieCTE m
LEFT JOIN 
    CompanyInfo ci ON m.movie_id = ci.movie_id AND ci.company_rank = 1
LEFT JOIN 
    KeyWordCount kc ON m.movie_id = kc.movie_id
WHERE 
    m.rank_by_cast <= 10
ORDER BY 
    m.production_year DESC, 
    m.total_cast DESC, 
    m.title;
