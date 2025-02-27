WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ak.name AS aka_name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        aka_title ak ON ak.movie_id = t.id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY 
        t.id, ak.name, ct.kind, t.title, t.production_year
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON r.id = ci.role_id
    GROUP BY 
        ci.movie_id
),
final_benchmark AS (
    SELECT 
        md.title,
        md.production_year,
        md.aka_name,
        md.company_type,
        md.keywords,
        cd.total_cast,
        cd.roles
    FROM 
        movie_details md
    JOIN 
        cast_details cd ON cd.movie_id = md.title_id
    ORDER BY 
        md.production_year DESC, 
        md.title
)

SELECT * FROM final_benchmark
WHERE keywords IS NOT NULL
AND total_cast > 5
ORDER BY company_type, total_cast DESC;

