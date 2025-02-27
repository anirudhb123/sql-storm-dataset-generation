WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS rk,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movie_count,
        COALESCE(NULLIF(t.title, ''), 'Untitled') AS safe_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(*) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
),
TitleInfo AS (
    SELECT 
        mt.movie_id,
        mt.info AS movie_info,
        mt.note AS info_note
    FROM 
        movie_info mt
    WHERE 
        mt.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
)

SELECT 
    rm.title AS movie_title,
    rm.production_year,
    mc.cast_count,
    mc.actor_names,
    cd.company_name,
    cd.num_movies,
    ti.movie_info,
    ti.info_note,
    (SELECT MAX(title) FROM aka_title WHERE production_year = rm.production_year) AS latest_title_of_year,
    CASE 
        WHEN mc.cast_count = 0 THEN 'No Cast'
        WHEN mc.cast_count > 5 THEN 'Large Cast'
        ELSE 'Normal Cast' END AS cast_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    TitleInfo ti ON rm.movie_id = ti.movie_id
WHERE 
    (cd.num_movies IS NULL OR cd.num_movies < 3) AND 
    (rm.rk = 1 OR rm.movie_count > 10) 
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;

This SQL query dives deep into the data schema provided, pulling a variety of fascinating pieces of information together. It leverages Common Table Expressions (CTEs) to segment various components: obtaining rankings of movies by production year, counting cast members, summarizing company details, and collating movie information. It incorporates outer joins to ensure all relevant data is included and also has predicates with multiple layers of logic to filter results creatively. The CASE statement provides an additional layer of categorization based on the number of cast members, enriching the final output with segmented insights.
