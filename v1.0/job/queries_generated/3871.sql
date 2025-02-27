WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
DistinctCompanies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(d.company_names, '{}') AS company_names,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        MAX(ci.nr_order) AS max_order
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        DistinctCompanies d ON t.id = d.movie_id
    GROUP BY 
        t.title, t.production_year, d.company_names
)
SELECT 
    md.title,
    md.production_year,
    md.company_names,
    md.num_actors,
    CASE 
        WHEN md.num_actors > 10 THEN 'High'
        WHEN md.num_actors BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS actor_density,
    (SELECT AVG(num_actors) FROM MovieDetails) AS avg_actors,
    (SELECT COUNT(*) FROM RankedTitles WHERE rank <= 5) AS top_ranked_count,
    (SELECT COUNT(*) FROM (SELECT DISTINCT title_id FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE k.keyword ILIKE '%action%') AS action_titles) AS action_movie_count
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, md.title
LIMIT 50;
