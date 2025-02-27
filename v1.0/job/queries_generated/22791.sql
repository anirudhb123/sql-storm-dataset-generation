WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY a.person_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),

MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.note AS company_note,
        string_agg(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword k ON mc.movie_id = k.movie_id
    GROUP BY 
        mt.movie_id, mt.note
),

SelectedMovies AS (
    SELECT 
        rt.actor_name,
        rt.movie_title,
        rt.production_year,
        md.companies,
        md.keyword_count,
        CASE 
            WHEN md.keyword_count > 0 THEN 'Keywords Available'
            ELSE 'No Keywords Available'
        END AS keyword_status
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MovieDetails md ON rt.year_rank = 1 AND rt.movie_title = md.movie_title
),

FinalResults AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        companies,
        keyword_count,
        keyword_status,
        COALESCE(companies, 'No associated companies') AS company_info
    FROM 
        SelectedMovies
    WHERE 
        production_year IS NOT NULL
    AND 
        (keyword_status = 'Keywords Available' OR production_year > 2000)
)

SELECT 
    *,
    CASE 
        WHEN production_year > 2020 THEN 'Latest Production'
        ELSE 'Earlier Production'
    END AS production_category
FROM 
    FinalResults
WHERE 
    actor_name IS NOT NULL
ORDER BY 
    production_year DESC,
    actor_name;
