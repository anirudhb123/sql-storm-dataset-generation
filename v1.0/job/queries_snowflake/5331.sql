
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id 
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_names,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 10
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    LISTAGG(DISTINCT f.company_names, ', ') WITHIN GROUP (ORDER BY f.company_names) AS companies,
    LISTAGG(DISTINCT f.keywords, ', ') WITHIN GROUP (ORDER BY f.keywords) AS tags
FROM 
    FilteredMovies f
GROUP BY 
    f.movie_id, f.title, f.production_year
ORDER BY 
    f.production_year DESC, f.title;
