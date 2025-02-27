WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
ranked_movies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.kind_id ORDER BY md.cast_count DESC) AS rn
    FROM 
        movie_data md
)

SELECT 
    rm.movie_title,
    rm.production_year,
    ct.kind AS kind_name,
    rm.cast_count,
    rm.aka_names,
    rm.keywords
FROM 
    ranked_movies rm
JOIN 
    kind_type ct ON rm.kind_id = ct.id
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.kind_id, rm.cast_count DESC;
