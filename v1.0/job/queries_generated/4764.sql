WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id
), 
RecentMovies AS (
    SELECT 
        title_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
), 
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title, 
        rm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        RecentMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.title_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON rm.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        rm.title_id, rm.title, rm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_names, 'No actors found') AS actors,
    COALESCE(md.company_names, 'No companies found') AS companies
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title ASC;
