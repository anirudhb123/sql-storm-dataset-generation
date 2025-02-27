WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS director_name,
        GROUP_CONCAT(DISTINCT ac.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id AND cn.country_code = 'USA'
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ac ON cc.subject_id = ac.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, a.name
),
Ranking AS (
    SELECT 
        title,
        production_year,
        director_name,
        cast_names,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY LENGTH(cast_names) DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    *
FROM 
    Ranking
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, rank;
