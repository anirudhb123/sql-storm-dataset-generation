WITH MovieDetails AS (
    SELECT 
        tt.id AS movie_id,
        tt.title,
        tt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title tt
    LEFT JOIN 
        movie_companies mc ON tt.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON tt.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        tt.id, tt.title, tt.production_year
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteDetails AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.aka_names,
        md.company_names,
        md.cast_count,
        kd.keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordDetails kd ON md.movie_id = kd.movie_id
)
SELECT 
    title,
    production_year,
    aka_names,
    company_names,
    cast_count,
    COALESCE(keywords, 'No keywords') AS keywords
FROM 
    CompleteDetails
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, 
    title;
