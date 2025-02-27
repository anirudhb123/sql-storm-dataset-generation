WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_member_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name co ON co.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year
),
average_cast_size AS (
    SELECT 
        AVG(cast_member_count) AS avg_cast_size
    FROM 
        ranked_movies
),
final_results AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_member_count,
        rm.aliases,
        rm.companies,
        rm.keywords,
        CASE 
            WHEN rm.cast_member_count > a.avg_cast_size THEN 'Above Average'
            ELSE 'Below Average'
        END AS cast_size_status
    FROM 
        ranked_movies rm, average_cast_size a
)

SELECT 
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.cast_member_count,
    fs.aliases,
    fs.companies,
    fs.keywords,
    fs.cast_size_status
FROM 
    final_results fs
ORDER BY 
    fs.production_year DESC, 
    fs.cast_member_count DESC;
