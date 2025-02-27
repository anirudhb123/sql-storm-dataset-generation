WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
), filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.rank_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_year <= 5
), movie_details AS (
    SELECT 
        fm.movie_id,
        fm.movie_title,
        fm.production_year,
        ak.name AS aka_name,
        cp.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        filtered_movies fm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = fm.movie_id
    LEFT JOIN 
        company_type cp ON cp.id = mc.company_type_id
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = fm.movie_id)
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = fm.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    STRING_AGG(DISTINCT md.aka_name, ', ') AS aka_names,
    STRING_AGG(DISTINCT md.company_type, ', ') AS production_companies,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
FROM 
    movie_details md
GROUP BY 
    md.movie_id, md.movie_title, md.production_year
ORDER BY 
    md.production_year DESC, md.movie_title;
