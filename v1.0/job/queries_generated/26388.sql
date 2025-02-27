WITH movie_rank AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id 
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id 
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id 
    LEFT JOIN 
        company_name co ON mc.company_id = co.id 
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id 
    WHERE 
        mt.production_year IS NOT NULL
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        cast_count,
        companies,
        keyword_count,
        RANK() OVER (ORDER BY cast_count DESC, keyword_count DESC) AS movie_rank
    FROM 
        movie_rank
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.aka_names,
    rm.cast_count,
    rm.companies,
    rm.keyword_count,
    rm.movie_rank
FROM 
    ranked_movies rm
WHERE 
    rm.cast_count >= 5
ORDER BY 
    rm.movie_rank
LIMIT 10;

