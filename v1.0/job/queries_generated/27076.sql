WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT c.id) AS cast_ids,
        GROUP_CONCAT(DISTINCT ci.person_role_id) AS role_ids,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
Popularity AS (
    SELECT 
        movie_title,
        production_year,
        company_count,
        CASE 
            WHEN company_count > 3 THEN 'Popular'
            ELSE 'Less Popular'
        END AS popularity_category,
        COUNT(cast_ids) AS cast_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year, company_count
)
SELECT 
    pd.movie_title,
    pd.production_year,
    pd.popularity_category,
    pd.cast_count,
    pd.company_count,
    pd.aka_names AS 'Alternative Names',
    pd.keywords AS 'Movie Keywords'
FROM 
    Popularity pd
ORDER BY 
    pd.production_year DESC, 
    pd.cast_count DESC;
