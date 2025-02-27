
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast,
        AVG(ki.score) AS avg_keyword_score
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN (
        SELECT 
            mk.movie_id, 
            COUNT(k.id) AS score
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON k.id = mk.keyword_id
        GROUP BY 
            mk.movie_id
    ) ki ON ki.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.production_year,
        rm.title,
        rm.rank_by_cast,
        COALESCE(ka.name, 'Unknown') AS actor_name,
        COUNT(mc.company_id) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = rm.title_id
    LEFT JOIN 
        aka_name ka ON ka.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = rm.title_id
    GROUP BY 
        rm.production_year, rm.title, rm.rank_by_cast, ka.name
    HAVING 
        rm.rank_by_cast <= 3  
),
FilteredMovies AS (
    SELECT 
        md.*,
        CASE 
            WHEN company_count > 5 THEN 'Big Production'
            WHEN company_count = 0 THEN 'Independent'
            ELSE 'Moderate Production'
        END AS production_type
    FROM 
        MovieDetails md
    WHERE 
        md.actor_name IS NOT NULL 
        AND md.production_year BETWEEN 2000 AND 2023
)
SELECT 
    fm.production_year,
    fm.title,
    fm.actor_name,
    fm.production_type,
    COUNT(DISTINCT mc.company_id) AS distinct_company_types,
    SUM(CASE WHEN mc.note LIKE '%special%' THEN 1 ELSE 0 END) AS special_company_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT title_id FROM RankedMovies WHERE title = fm.title LIMIT 1)
GROUP BY 
    fm.production_year, fm.title, fm.actor_name, fm.production_type
ORDER BY 
    fm.production_year DESC, fm.production_type, fm.title;
