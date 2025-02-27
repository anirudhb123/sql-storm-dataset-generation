WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS alternate_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT p.info, ';') AS person_info
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        person_info p ON cc.subject_id = p.person_id
    GROUP BY 
        t.id
),
FilteredMovies AS (
    SELECT 
        md.*,
        COUNT(cc.id) AS cast_count,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_companies mc ON md.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        md.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.alternate_names,
    fm.keywords,
    fm.person_info,
    fm.companies
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC
LIMIT 100;
