
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_list,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),

AvgProductionYear AS (
    SELECT 
        AVG(production_year) AS avg_year
    FROM 
        aka_title
    WHERE 
        production_year IS NOT NULL
)

SELECT 
    md.movie_title,
    md.production_year,
    md.cast_list,
    md.keywords,
    md.company_names,
    ap.avg_year
FROM 
    MovieDetails md,
    AvgProductionYear ap
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
