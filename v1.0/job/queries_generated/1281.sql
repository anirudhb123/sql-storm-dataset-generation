WITH movie_cast AS (
    SELECT 
        ct.movie_id, 
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    INNER JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        ct.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        t.title, 
        t.production_year, 
        mc.total_cast, 
        mk.keywords
    FROM 
        title t
    LEFT JOIN 
        movie_cast mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
)
SELECT 
    md.title, 
    md.production_year, 
    COALESCE(md.total_cast, 0) AS total_cast, 
    COALESCE(md.keywords, 'No keywords') AS keywords,
    ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.title) AS rn
FROM 
    movie_details md
WHERE 
    (md.total_cast IS NULL OR md.total_cast > 5)
    AND (md.keywords IS NOT NULL OR md.production_year < 2010)
ORDER BY 
    md.production_year DESC, 
    md.title;
