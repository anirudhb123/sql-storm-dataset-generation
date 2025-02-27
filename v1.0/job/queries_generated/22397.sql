WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ki.kind AS kind_name,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(char.name, 'Unknown Character') AS character_name,
        COUNT(ci.person_id) OVER (PARTITION BY t.id) AS total_cast,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        SUM(CASE WHEN c.gender = 'F' THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS female_cast_count,
        SUM(CASE WHEN c.gender = 'M' THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS male_cast_count
    FROM 
        title t
    LEFT JOIN 
        kind_type ki ON t.kind_id = ki.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        name c ON ci.person_id = c.id
    LEFT JOIN 
        char_name char ON t.id = char.imdb_id
    WHERE 
        t.production_year IS NOT NULL
        AND (t.production_year >= 2000 OR t.title LIKE '%Avengers%')
        AND COALESCE(c.gender, 'N') != 'N'
)

SELECT 
    md.title,
    md.production_year,
    md.kind_name,
    md.keyword,
    md.character_name,
    NULLIF(md.total_cast, 0) AS total_cast,
    md.cast_names,
    md.female_cast_count,
    md.male_cast_count,
    CASE 
        WHEN md.total_cast IS NULL THEN 'No Cast Information'
        WHEN md.female_cast_count > md.male_cast_count THEN 'More Female Cast'
        ELSE 'More Male Cast or Equal'
    END AS cast_gender_balance
FROM
    MovieDetails md
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = md.title_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    )
ORDER BY 
    md.production_year DESC,
    md.title ASC
LIMIT 100

UNION ALL

SELECT 
    DISTINCT
    'Aggregation of All Movies without Cast' AS title,
    NULL AS production_year,
    NULL AS kind_name,
    NULL AS keyword,
    NULL AS character_name,
    COUNT(DISTINCT t.id) AS total_cast,
    NULL AS cast_names,
    NULL AS female_cast_count,
    NULL AS male_cast_count,
    'No Cast Data Available' AS cast_gender_balance
FROM 
    title AS t 
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = t.id
    )
ORDER BY 
    total_cast DESC
LIMIT 100;
