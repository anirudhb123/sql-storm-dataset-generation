
WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ARRAY_AGG(DISTINCT ka.name) AS aka_names,
        COUNT(DISTINCT c.person_id) AS total_actors,
        a.id AS movie_id
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ka ON c.person_id = ka.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
AwardNominations AS (
    SELECT 
        mi.movie_id,
        COUNT(*) AS total_nominations
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'award nomination')
    GROUP BY 
        mi.movie_id
),
RankedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        COALESCE(ai.total_nominations, 0) AS awards_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY COALESCE(ai.total_nominations, 0) DESC) AS rank,
        md.movie_id
    FROM 
        MovieDetails md
    LEFT JOIN 
        AwardNominations ai ON md.movie_id = ai.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.awards_count,
    ci.company_name,
    ci.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id 
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.awards_count DESC;
