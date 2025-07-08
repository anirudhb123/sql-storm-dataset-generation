
WITH MovieDetails AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS actor_count,
        LISTAGG(DISTINCT cn.name, ', ') AS companies,
        AVG(CAST(mi.info AS NUMBER)) AS average_rating
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
RankedMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        companies,
        average_rating,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank_per_year
    FROM 
        MovieDetails
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN average_rating IS NULL THEN 'No Rating' 
            ELSE 'Rated'
        END AS rating_status
    FROM 
        RankedMovies
    WHERE 
        actor_count > 0
)
SELECT 
    title,
    production_year,
    actor_count,
    companies,
    average_rating,
    rating_status
FROM 
    FilteredMovies
WHERE 
    rank_per_year <= 5
ORDER BY 
    production_year, rank_per_year;
