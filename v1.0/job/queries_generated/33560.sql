WITH RECURSIVE MoviesCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m 
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        c.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        MoviesCTE c ON m.episode_of_id = c.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        MoviesCTE m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
Ranking AS (
    SELECT 
        movie_id, title, production_year,
        total_cast,
        total_keywords,
        keywords_list,
        total_companies,
        RANK() OVER (ORDER BY total_cast DESC, production_year ASC) AS cast_rank
    FROM 
        MovieDetails 
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.total_cast,
    r.total_keywords,
    r.keywords_list,
    r.total_companies,
    CASE 
        WHEN r.total_cast IS NULL THEN 'No Cast Available'
        ELSE 'Cast Available'
    END AS cast_status,
    CASE 
        WHEN r.cast_rank <= 5 THEN 'Top 5 Movies by Cast'
        ELSE 'Not in Top 5'
    END AS rank_status
FROM 
    Ranking r
WHERE 
    r.total_companies > 0
ORDER BY 
    r.cast_rank, r.production_year DESC;
