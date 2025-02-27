WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.person_id,
        MAX(a.name) AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id
),
movie_details AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        ai.actor_name,
        ai.movie_count,
        COALESCE(mt.kind, 'Unknown') AS movie_type
    FROM 
        ranked_movies r
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    LEFT JOIN 
        actor_info ai ON ci.person_id = ai.person_id
    LEFT JOIN 
        kind_type mt ON r.id = mt.id
    WHERE 
        r.rank <= 5 -- Only top 5 recent movies per year
),
full_movie_info AS (
    SELECT 
        md.*,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        movie_details md
    LEFT JOIN 
        movie_keyword mk ON md.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.actor_name, md.movie_count, md.movie_type
),
final_selection AS (
    SELECT 
        *,
        CASE 
            WHEN production_year < 2000 THEN 'Classic'
            WHEN production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        full_movie_info
    WHERE 
        actor_name IS NOT NULL
)
SELECT 
    f.title,
    f.production_year,
    f.actor_name,
    f.movie_count,
    f.keywords,
    f.era,
    CASE 
        WHEN movie_count > 10 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS actor_category
FROM 
    final_selection f
WHERE 
    f.movie_count > 2
ORDER BY 
    f.production_year DESC, f.movie_count DESC
LIMIT 50;
