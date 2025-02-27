WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT c.id) AS num_cast_members
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
averages AS (
    SELECT 
        production_year,
        AVG(num_cast_members) AS avg_cast_members,
        STRING_AGG(DISTINCT keywords, ', ') AS keyword_summary
    FROM 
        movie_details
    GROUP BY 
        production_year
)
SELECT 
    dh.production_year,
    dh.avg_cast_members,
    dh.keyword_summary
FROM 
    averages dh
ORDER BY 
    dh.production_year DESC;
