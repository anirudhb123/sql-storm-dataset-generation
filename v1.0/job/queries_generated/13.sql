WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title, 
        mt.production_year, 
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS yearly_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
    GROUP BY 
        mt.id
),
HighCompanyCount AS (
    SELECT 
        movie_title, 
        production_year 
    FROM 
        MovieDetails 
    WHERE 
        company_count > 5 
)
SELECT 
    m.movie_title,
    m.production_year,
    COALESCE(hcc.yearly_rank, 'No Rank') AS rank,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.id) AS info_count
FROM 
    MovieDetails m
LEFT JOIN 
    HighCompanyCount hcc ON m.movie_title = hcc.movie_title
ORDER BY 
    m.production_year DESC, 
    m.movie_title;
