WITH ranked_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank,
        COALESCE(mci.note, 'N/A') AS company_note
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN 
        movie_companies mci ON t.id = mci.movie_id AND mci.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
),
actor_summary AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS total_movies,
        MAX(production_year) AS last_movie_year
    FROM 
        ranked_titles
    WHERE 
        rank <= 5
    GROUP BY 
        actor_name
),
movies_with_keywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    asum.actor_name,
    asum.total_movies,
    asum.last_movie_year,
    COUNT(DISTINCT mwk.movie_id) AS keyword_movie_count,
    STRING_AGG(DISTINCT mwk.keyword, ', ') AS keywords,
    CASE 
        WHEN asum.total_movies > 10 THEN 'Veteran'
        WHEN asum.total_movies BETWEEN 5 AND 10 THEN 'Rising Star'
        ELSE 'Newcomer'
    END AS actor_status
FROM 
    actor_summary asum
LEFT JOIN 
    movies_with_keywords mwk ON asum.actor_name = mwk.title
GROUP BY 
    asum.actor_name, asum.total_movies, asum.last_movie_year
HAVING 
    SUM(CASE WHEN mwk.keyword IS NULL THEN 1 ELSE 0 END) < 3
ORDER BY 
    asum.last_movie_year DESC, asum.actor_name;
