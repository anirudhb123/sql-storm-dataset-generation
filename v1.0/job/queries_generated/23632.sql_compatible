
WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(NULLIF(k.keyword, ''), 'No Keyword') AS keyword,
        m.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword DESC NULLS LAST) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
        AND TRIM(t.title) != ''
),
CastingData AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS validated_cast,
        AVG(CASE WHEN ci.note IS NOT NULL AND ci.note <> '' THEN 1 ELSE 0 END) AS note_non_empty_ratio,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name n ON ci.person_id = n.person_id
    GROUP BY 
        ci.movie_id
),
FullMovieStats AS (
    SELECT 
        md.*,
        cd.total_cast,
        cd.validated_cast,
        ROUND(CAST(cd.note_non_empty_ratio AS numeric), 2) AS note_ratio,
        cd.cast_names
    FROM 
        MovieData md
    LEFT JOIN 
        CastingData cd ON md.movie_id = cd.movie_id
    WHERE 
        md.keyword_rank = 1 
        OR md.production_year IS NOT NULL
)
SELECT 
    fms.movie_id,
    fms.title,
    fms.production_year,
    fms.keyword,
    fms.company_name,
    fms.company_type,
    fms.total_cast,
    fms.validated_cast,
    CASE 
        WHEN fms.note_ratio IS NULL THEN 'No Data' 
        ELSE CONCAT(fms.note_ratio, '%') 
    END AS note_ratio_percentage,
    CASE 
        WHEN fms.cast_names IS NULL THEN 'No Cast Data' 
        ELSE fms.cast_names 
    END AS detailed_cast_names
FROM 
    FullMovieStats fms
WHERE 
    (fms.total_cast > 5 AND fms.validated_cast / NULLIF(fms.total_cast, 0) > 0.5)
    OR (fms.production_year < 2020 AND fms.company_name IS NOT NULL)
ORDER BY 
    fms.production_year DESC, 
    fms.title ASC;
