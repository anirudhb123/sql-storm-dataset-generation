WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = at.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA')
),
KeywordCount AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mt.id = mk.movie_id
    GROUP BY 
        mt.movie_id
),
MovieInfo AS (
    SELECT 
        mt.title,
        mt.production_year,
        ki.keyword_count,
        COUNT(DISTINCT pi.info) AS info_count
    FROM 
        RankedTitles mt
    LEFT JOIN 
        KeywordCount ki ON ki.movie_id = mt.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = mt.id
    LEFT JOIN 
        info_type it ON it.id = mi.info_type_id
    GROUP BY 
        mt.title, mt.production_year, ki.keyword_count
)

SELECT 
    m.title,
    m.production_year,
    m.keyword_count,
    m.info_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors
FROM 
    MovieInfo m
JOIN 
    aka_title at ON m.title = at.title AND m.production_year = at.production_year
JOIN 
    cast_info ci ON ci.movie_id = at.id
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
GROUP BY 
    m.title, m.production_year, m.keyword_count, m.info_count
ORDER BY 
    m.production_year DESC, m.title ASC;
