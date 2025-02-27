WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(mk.keyword_id) OVER (PARTITION BY t.id) AS keyword_count,
        COALESCE(NULLIF(AVG(CASE WHEN pc.info IS NOT NULL THEN pc.info::float END), 0), -1) AS average_person_rating
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        person_info pc ON mi.id = pc.info_type_id
    WHERE 
        t.production_year IS NOT NULL AND 
        (t.kind_id IN (SELECT DISTINCT kind_id FROM kind_type WHERE kind LIKE 'F%') OR t.kind_id IS NULL)
),

MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.rank_by_title,
        rm.keyword_count,
        COALESCE(rc.role, 'Not Assigned') AS role_name,
        CASE 
            WHEN rm.average_person_rating > 7 THEN 'Highly Rated'
            WHEN rm.average_person_rating IS NULL THEN 'No Rating Available'
            ELSE 'Moderately Rated or Unpopular'
        END AS rating_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info c ON rm.title = c.note
    LEFT JOIN 
        role_type rc ON c.role_id = rc.id
),

FinalResults AS (
    SELECT 
        md.*,
        COUNT(DISTINCT c.id) OVER (PARTITION BY md.production_year ORDER BY md.rank_by_title) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS companies_in_title
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_companies mc ON md.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        md.keyword_count > 0
)

SELECT 
    title,
    production_year,
    rank_by_title,
    keyword_count,
    role_name,
    rating_category,
    company_count,
    companies_in_title
FROM 
    FinalResults
WHERE 
    role_name NOT LIKE '%Extra%'
ORDER BY 
    production_year DESC, 
    title ASC;
