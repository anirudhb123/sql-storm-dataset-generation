WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
cast_details AS (
    SELECT 
        t.title AS movie_title,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_members,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        t.id, t.title
),
final_benchmark AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_type,
        md.aka_names,
        cd.cast_members,
        cd.cast_count,
        CASE 
            WHEN md.production_year < 2000 THEN 'Classic'
            WHEN md.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
            ELSE 'Recent'
        END AS movie_era
    FROM 
        movie_details md
    JOIN 
        cast_details cd ON md.movie_title = cd.movie_title
    ORDER BY 
        md.production_year DESC
)
SELECT 
    movie_title,
    production_year,
    company_type,
    aka_names,
    cast_members,
    cast_count,
    movie_era
FROM 
    final_benchmark
WHERE 
    company_type IS NOT NULL
LIMIT 100;
