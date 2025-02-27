WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        c.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND c.country_code IS NOT NULL
),
MovieStats AS (
    SELECT 
        movie_id,
        COUNT(*) AS company_count,
        COUNT(DISTINCT keyword) AS unique_keywords
    FROM 
        RankedMovies
    WHERE 
        rn <= 5 -- limit to top 5 movies per kind
    GROUP BY 
        movie_id
)
SELECT 
    m.title,
    m.production_year,
    ms.company_count,
    ms.unique_keywords,
    CASE 
        WHEN ms.unique_keywords = 0 THEN 'No Keywords'
        WHEN ms.unique_keywords < 3 THEN 'Few Keywords'
        ELSE 'Many Keywords'
    END AS keyword_description,
    COALESCE(cast_info.note, 'N/A') AS cast_note,
    CHAR_LENGTH(m.title) AS title_length,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
FROM 
    aka_title m
LEFT JOIN 
    MovieStats ms ON m.id = ms.movie_id
LEFT JOIN 
    cast_info ON m.id = cast_info.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    m.id, ms.company_count, ms.unique_keywords, cast_info.note
ORDER BY 
    m.production_year DESC,
    m.title_length DESC,
    ms.unique_keywords DESC
LIMIT 
    10;
