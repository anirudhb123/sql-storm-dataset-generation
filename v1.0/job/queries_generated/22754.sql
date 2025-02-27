WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
movies_with_companies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY rm.movie_id ORDER BY mc.company_id) AS company_rank
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 
final_results AS (
    SELECT 
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        mwc.company_name,
        mwc.company_type,
        mwc.company_rank,
        COUNT(*) OVER (PARTITION BY mwc.movie_id) AS total_companies,
        CASE 
            WHEN mwc.production_year < 2000 THEN 'Classic'
            WHEN mwc.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
            ELSE 'Contemporary'
        END AS movie_era,
        COALESCE(mwc.actor_names, 'No Actors Listed') AS actors
    FROM 
        movies_with_companies mwc
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.company_name,
    fr.company_type,
    fr.company_rank,
    fr.total_companies,
    fr.movie_era,
    fr.actors
FROM 
    final_results fr
WHERE 
    fr.total_companies > 1 AND
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = fr.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
    )
ORDER BY 
    fr.production_year DESC, 
    fr.movie_id;
