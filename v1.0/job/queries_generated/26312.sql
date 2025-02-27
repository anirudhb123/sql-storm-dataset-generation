WITH MovieStatistics AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS main_actors,
        COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

FormattedStats AS (
    SELECT 
        movie_title,
        production_year,
        total_cast_members,
        main_actors,
        total_keywords,
        CONCAT(movie_title, ' (', production_year, ') with ', total_cast_members, ' cast members including ', main_actors, ' has ', total_keywords, ' keywords.') AS formatted_string
    FROM 
        MovieStatistics
)

SELECT 
    formatted_string
FROM 
    FormattedStats
ORDER BY 
    production_year DESC, total_cast_members DESC
LIMIT 10;
