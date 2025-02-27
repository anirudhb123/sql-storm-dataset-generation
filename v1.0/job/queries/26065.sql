
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT km.keyword) AS keyword_count
    FROM 
        aka_title AS mt
    INNER JOIN 
        movie_companies AS mc ON mt.id = mc.movie_id
    INNER JOIN 
        cast_info AS c ON mt.id = c.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword AS km ON mk.keyword_id = km.id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000 
        AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
StatisticalAnalysis AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actor_names,
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank_by_cast,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC) AS rank_by_keywords
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    actor_names,
    keyword_count,
    rank_by_cast,
    rank_by_keywords
FROM 
    StatisticalAnalysis
WHERE 
    rank_by_cast <= 10 
    OR rank_by_keywords <= 10
ORDER BY 
    rank_by_cast, rank_by_keywords;
