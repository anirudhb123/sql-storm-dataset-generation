
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.production_year DESC, CHAR_LENGTH(md.actors) DESC) AS rank
    FROM 
        MovieDetails md
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        actors,
        production_companies
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    fm.production_year,
    COUNT(*) AS total_movies,
    AVG(production_companies) AS avg_production_companies
FROM 
    FilteredMovies fm
GROUP BY 
    fm.production_year
ORDER BY 
    fm.production_year DESC;
