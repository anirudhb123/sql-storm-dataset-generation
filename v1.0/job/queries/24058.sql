WITH movie_data AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        COUNT(ci.id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN LENGTH(ci.note) ELSE 0 END) AS avg_note_length
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
    GROUP BY 
        t.title, t.production_year, k.keyword
),
company_data AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS rn
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
),
overall_data AS (
    SELECT 
        md.title,
        md.production_year,
        COALESCE(cd.company_name, 'Unknown Company') AS company_name,
        COALESCE(cd.company_type, 'Independent') AS company_type,
        md.keyword,
        md.cast_count,
        md.avg_note_length
    FROM 
        movie_data md
    FULL OUTER JOIN 
        company_data cd ON md.title = (SELECT title FROM aka_title WHERE id = cd.movie_id LIMIT 1)
)
SELECT 
    title,
    production_year,
    company_name,
    company_type,
    keyword,
    cast_count,
    avg_note_length,
    CASE 
        WHEN avg_note_length > 0 THEN 'Notes exist'
        ELSE 'No notes'
    END AS note_existence,
    CASE 
        WHEN production_year IS NULL THEN 'Year Not Available'
        ELSE 'Year Available'
    END AS year_availability
FROM 
    overall_data
WHERE 
    (keyword IS NOT NULL AND cast_count > 0) 
    OR (company_name = 'Unknown Company' AND avg_note_length < 100)
ORDER BY 
    production_year DESC, cast_count DESC, title;
