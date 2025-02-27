WITH MovieAdvancedInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(k.id) AS keyword_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        JSON_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
PopularTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        keyword_count,
        keywords,
        companies,
        cast_count,
        cast_names
    FROM 
        MovieAdvancedInfo
    WHERE 
        production_year >= 2000 
    ORDER BY 
        cast_count DESC, keyword_count DESC
    LIMIT 10
)
SELECT 
    pt.title,
    pt.production_year,
    pt.cast_count,
    pt.keywords,
    pt.companies
FROM 
    PopularTitles pt
JOIN 
    aka_title at ON pt.title = at.title
WHERE 
    at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
ORDER BY 
    pt.production_year DESC;
