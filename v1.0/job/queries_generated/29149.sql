WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000 AND 
        cn.country_code = 'USA'
    GROUP BY 
        m.id
),
movie_rankings AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        aka_names,
        keywords,
        RANK() OVER (ORDER BY total_cast DESC) AS ranking
    FROM 
        ranked_movies
)
SELECT 
    mr.ranking,
    mr.movie_id,
    mr.title,
    mr.production_year,
    mr.total_cast,
    mr.aka_names,
    mr.keywords
FROM 
    movie_rankings mr
WHERE 
    mr.ranking <= 10
ORDER BY 
    mr.ranking;
