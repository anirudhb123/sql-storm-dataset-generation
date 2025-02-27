WITH RECURSIVE bag_of_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.movie_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(c.movie_id) > 5
), ranked_movies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM 
        bag_of_movies
), movie_details AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        rm.cast_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword mk ON rm.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON rm.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        rank_within_year <= 3
), movie_info_summaries AS (
    SELECT 
        title,
        production_year,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        SUM(cast_count) AS total_cast
    FROM 
        movie_details
    GROUP BY 
        title, production_year
)
SELECT 
    movie_summary.title,
    movie_summary.production_year,
    movie_summary.keywords,
    movie_summary.companies,
    movie_summary.total_cast
FROM 
    movie_info_summaries movie_summary
WHERE 
    movie_summary.production_year >= 2010
ORDER BY 
    movie_summary.production_year DESC, 
    movie_summary.total_cast DESC;
