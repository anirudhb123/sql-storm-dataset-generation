WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT c.name SEPARATOR ', ') AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id
),
GenreCounts AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT ct.kind) AS genre_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.cast_names,
    md.keywords,
    gc.genre_count
FROM 
    MovieDetails md
LEFT JOIN 
    GenreCounts gc ON md.id = gc.movie_id
ORDER BY 
    md.production_year DESC,
    md.movie_title ASC;
