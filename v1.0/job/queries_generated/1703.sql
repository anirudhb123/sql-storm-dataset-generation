WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    ),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        cm.name AS company_name,
        pi.info AS person_info
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        person_info pi ON cc.subject_id = pi.person_id
    WHERE 
        pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'bio')
),
GenreAvg AS (
    SELECT 
        k.keyword,
        AVG(m.production_year) AS avg_year
    FROM 
        movie_keyword mk
    JOIN 
        aka_title a ON mk.movie_id = a.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        k.keyword
)
SELECT 
    md.movie_id,
    md.title,
    md.keyword,
    md.company_name,
    ge.avg_year,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era,
    CASE 
        WHEN md.keyword = 'No Keywords' THEN 'N/A'
        ELSE md.keyword
    END AS adjusted_keyword
FROM 
    MovieDetails md
LEFT JOIN 
    GenreAvg ge ON md.keyword = ge.keyword
WHERE 
    md.company_name IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    adjusted_keyword ASC
LIMIT 100;
