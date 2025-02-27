WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        array_agg(DISTINCT ak.name) AS aka_names,
        array_agg(DISTINCT c.name) AS cast_names,
        count(DISTINCT c.id) AS cast_count,
        array_agg(DISTINCT k.keyword) AS keywords,
        string_agg(DISTINCT ci.kind, ', ') AS company_types
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c_info ON t.id = c_info.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c_info.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_type ci ON ci.id = mc.company_type_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.id
),
final_benchmark AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.cast_count,
        md.aka_names,
        md.keywords,
        md.company_types,
        CASE 
            WHEN md.production_year IS NOT NULL THEN 
                CASE 
                    WHEN md.production_year < 2000 THEN 'Classic'
                    WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
                    ELSE 'Recent'
                END
            ELSE 'Unknown'
        END AS era
    FROM 
        movie_details md
)
SELECT 
    fb.movie_id,
    fb.movie_title,
    fb.production_year,
    fb.cast_count,
    fb.aka_names,
    fb.keywords,
    fb.company_types,
    fb.era
FROM 
    final_benchmark fb
WHERE 
    fb.cast_count > 5
ORDER BY 
    fb.production_year DESC, fb.cast_count DESC, fb.movie_title;
