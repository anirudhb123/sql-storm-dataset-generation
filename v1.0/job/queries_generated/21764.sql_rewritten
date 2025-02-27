WITH RECURSIVE actor_appearances AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER(PARTITION BY c.movie_id ORDER BY c.nr_order) AS appearance_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL AND a.name <> ''
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT ca.subject_id) AS total_cast,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        title t
    LEFT JOIN 
        complete_cast ca ON t.id = ca.movie_id
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, mk.keywords
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.total_cast,
        md.total_companies,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC, md.total_companies DESC) AS rank_in_year
    FROM 
        movie_details md
    WHERE 
        md.production_year IS NOT NULL
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.total_cast,
    rm.total_companies,
    rm.rank_in_year,
    a.actor_name AS top_actor,
    (SELECT COUNT(*) FROM aka_name WHERE person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = rm.movie_id)) AS different_actors_count,
    CASE 
        WHEN rm.rank_in_year = 1 THEN 'Top Movie of Year'
        ELSE 'Not Top Movie'
    END AS movie_rank_status
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_appearances a ON rm.movie_id = a.movie_id AND a.appearance_order = 1
WHERE 
    rm.total_cast >= 5
ORDER BY 
    rm.production_year DESC, 
    rm.rank_in_year;