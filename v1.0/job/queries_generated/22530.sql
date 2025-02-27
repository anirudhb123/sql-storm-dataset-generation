WITH RecursiveMovieCTE AS (
    SELECT 
        title.movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka.name, ', ') AS actors_list,
        ROW_NUMBER() OVER (PARTITION BY title.movie_id ORDER BY title.production_year DESC) AS rn
    FROM 
        aka_title AS title
    LEFT JOIN 
        cast_info AS cast ON title.id = cast.movie_id
    LEFT JOIN 
        aka_name AS aka ON cast.person_id = aka.person_id
    WHERE 
        title.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        title.movie_id,
        title.title,
        title.production_year
),
MovieCompanyCTE AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies,
        MAX(CASE WHEN ct.kind = 'distributor' THEN cn.name END) AS distributor_name
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
RankedMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.cast_count,
        r.actors_list,
        mc.companies,
        mc.distributor_name,
        CASE 
            WHEN r.cast_count > 20 THEN 'Big Cast'
            WHEN r.cast_count BETWEEN 10 AND 20 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        RecursiveMovieCTE r
    LEFT JOIN 
        MovieCompanyCTE mc ON r.movie_id = mc.movie_id
    WHERE 
        r.production_year IS NOT NULL
)
SELECT 
    *,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) <= 5 THEN 'Top 5 Movies of Year'
        ELSE 'Other Movies'
    END AS ranking_category,
    COALESCE(distributor_name, 'Unknown Distributor') AS final_distributor
FROM 
    RankedMovies
WHERE 
    NOT EXISTS (
        SELECT 1 FROM movie_info mi 
        WHERE mi.movie_id = RankedMovies.movie_id 
        AND mi.info LIKE '%failed%'
    )
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 100;
