WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ca.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS alternate_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ca ON ca.movie_id = t.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ca.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year, c.name
    HAVING 
        COUNT(DISTINCT ca.id) > 5
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_name,
        md.cast_count,
        md.alternate_names,
        md.keywords,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS rank
    FROM 
        movie_details md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_name,
    rm.cast_count,
    rm.alternate_names,
    rm.keywords
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
