WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
BaseInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        CASE 
            WHEN m.production_year >= 2000 THEN 'Modern'
            ELSE 'Classic'
        END AS era,
        (SELECT 
            STRING_AGG(c.name, ', ') 
         FROM 
            aka_name c 
         JOIN 
            cast_info ci ON ci.person_id = c.person_id 
         WHERE 
            ci.movie_id = m.movie_id) AS actors
    FROM 
        RankedMovies m 
    WHERE 
        year_rank <= 5
),
LowestBudgetMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        mb.budget
    FROM 
        BaseInfo m
    LEFT JOIN 
        movie_info mb ON m.movie_id = mb.movie_id AND mb.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    WHERE 
        mb.budget IS NOT NULL
    ORDER BY 
        mb.budget ASC
    LIMIT 5
)
SELECT 
    b.movie_id,
    b.title,
    b.production_year,
    b.era,
    COALESCE(lb.budget, 'Not Available') AS budget_info,
    b.actors
FROM 
    BaseInfo b
LEFT JOIN 
    LowestBudgetMovies lb ON b.movie_id = lb.movie_id
WHERE 
    b.production_year BETWEEN 1990 AND 2023
AND 
    b.cast_count > 1
ORDER BY 
    b.production_year DESC, 
    b.title;
