WITH movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        t.note AS movie_note,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, t.note
),
top_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.kind_id,
        md.movie_note,
        md.keywords,
        md.companies,
        md.cast_count,
        ROW_NUMBER() OVER (ORDER BY md.cast_count DESC) AS rank
    FROM 
        movie_details md
)
SELECT 
    tm.movie_id, 
    tm.title, 
    tm.production_year, 
    tm.kind_id, 
    tm.movie_note,
    tm.keywords, 
    tm.companies, 
    tm.cast_count
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;

This query generates a ranking of the top 10 movies based on the count of distinct cast members, while also aggregating related keywords and company names associated with each film.
