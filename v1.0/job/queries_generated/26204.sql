WITH movie_characteristics AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS character_name,
        p.gender,
        k.keyword AS movie_keyword,
        cmp.name AS company_name,
        cmp.country_code
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        name p ON c.person_id = p.imdb_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cmp ON mc.company_id = cmp.id
    WHERE 
        t.production_year >= 2000
        AND (k.keyword ILIKE '%action%' OR k.keyword ILIKE '%drama%')
),
aggregate_data AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT character_name) AS unique_characters,
        STRING_AGG(DISTINCT company_name, ', ') AS producing_companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS associated_keywords,
        MIN(production_year) AS earliest_year
    FROM 
        movie_characteristics
    GROUP BY 
        movie_title
)
SELECT 
    movie_title,
    unique_characters,
    producing_companies,
    associated_keywords,
    earliest_year,
    CASE 
        WHEN unique_characters > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_level
FROM 
    aggregate_data
ORDER BY 
    earliest_year DESC, unique_characters DESC;
