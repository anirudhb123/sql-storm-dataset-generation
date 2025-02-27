WITH MovieCast AS (
    SELECT 
        ct.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        MIN(t.production_year) AS earliest_year
    FROM 
        cast_info ci
    JOIN aka_name ak ON ak.person_id = ci.person_id
    JOIN aka_title at ON at.id = ci.movie_id
    JOIN title t ON t.id = at.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie') AND
        ak.name IS NOT NULL
    GROUP BY 
        ct.movie_id
),
MovieKeyword AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
FullMovieInfo AS (
    SELECT 
        m.id,
        m.title,
        COALESCE(mc.total_cast, 0) AS total_cast,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        m.production_year,
        COALESCE(mc.earliest_year, m.production_year) AS earliest_year,
        'Directed by ' || COALESCE((SELECT STRING_AGG(CAST(d.name AS text), ', ') 
                                    FROM movie_companies mc 
                                    JOIN company_name d ON mc.company_id = d.id 
                                    WHERE mc.movie_id = m.id 
                                    AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')), 
                                    'Unknown Director') || 
        ' | Cast: ' || COALESCE(mc.cast_names, 'No Cast') AS cast_info
    FROM 
        title m
    LEFT JOIN MovieCast mc ON mc.movie_id = m.id
    LEFT JOIN MovieKeyword mk ON mk.movie_id = m.id
    WHERE 
        m.production_year > (SELECT AVG(production_year) FROM title WHERE production_year IS NOT NULL)
        OR EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = m.id AND mi.info ILIKE '%award%')
    ORDER BY 
        m.production_year DESC,
        total_cast DESC
)
SELECT 
    *,
    CASE 
        WHEN total_cast > 0 THEN ROUND(CAST(100.0 * (early_years - production_year) AS NUMERIC), 2)
        ELSE NULL
    END AS year_difference
FROM 
    FullMovieInfo
WHERE 
    keywords NOT ILIKE '%romantic%' 
    AND keywords ILIKE '%action%'
    AND NOT EXISTS (
        SELECT 1 
        FROM complete_cast cc 
        WHERE cc.movie_id = FullMovieInfo.id AND cc.status_id = (SELECT id FROM info_type WHERE info = 'unreleased')
    )
LIMIT 20;
