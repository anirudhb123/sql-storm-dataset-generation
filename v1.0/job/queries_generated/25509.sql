WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS actor_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind SEPARATOR ', ') AS company_types,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
        JOIN movie_info mi ON t.id = mi.movie_id
        JOIN movie_keyword mk ON t.id = mk.movie_id
        JOIN keyword k ON mk.keyword_id = k.id
        LEFT JOIN complete_cast cc ON t.id = cc.movie_id
        LEFT JOIN cast_info cinfo ON cc.subject_id = cinfo.id
        LEFT JOIN aka_name a ON cinfo.person_id = a.person_id
        LEFT JOIN movie_companies mc ON t.id = mc.movie_id
        LEFT JOIN company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
    GROUP BY 
        t.id, t.title, t.production_year
), movie_ranking AS (
    SELECT 
        movie_title,
        production_year,
        actor_names,
        keywords,
        company_types,
        company_count,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, company_count DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    rank,
    movie_title,
    production_year,
    actor_names,
    keywords,
    company_types,
    company_count
FROM 
    movie_ranking
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, rank;

This SQL query benchmarks string processing by aggregating and ranking data from various tables in the database. It focuses on movies produced since the year 2000, collecting relevant information such as actors, keywords, and company types, and ultimately returns the top 10 movies based on production year and company count.
