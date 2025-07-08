
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COALESCE(ARRAY_AGG(DISTINCT an.name), 'No Actors') AS actors
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS production_companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
keyword_details AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_benchmark AS (
    SELECT 
        md.movie_title,
        md.production_year,
        cd.production_companies,
        kd.keywords,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        movie_details AS md
    LEFT JOIN 
        company_details AS cd ON md.movie_title = (
            SELECT title FROM aka_title WHERE id = cd.movie_id
        )
    LEFT JOIN 
        cast_info AS ca ON md.movie_title = (
            SELECT title FROM aka_title WHERE id = ca.movie_id
        )
    LEFT JOIN 
        keyword_details AS kd ON md.movie_title = (
            SELECT title FROM aka_title WHERE id = kd.movie_id
        )
    GROUP BY 
        md.movie_title, md.production_year, cd.production_companies, kd.keywords
)
SELECT 
    movie_title,
    production_year,
    production_companies,
    keywords,
    actor_count
FROM 
    final_benchmark
ORDER BY 
    production_year DESC, actor_count DESC;
