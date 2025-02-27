WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aliases,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.company_name) AS production_companies,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ca.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), ranking AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aliases,
        keywords,
        production_companies,
        cast_count,
        RANK() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank
    FROM 
        movie_details
)
SELECT 
    r.rank,
    r.title,
    r.production_year,
    r.aliases,
    r.keywords,
    r.production_companies,
    r.cast_count
FROM 
    ranking r
WHERE 
    r.rank <= 10
ORDER BY 
    r.rank;
