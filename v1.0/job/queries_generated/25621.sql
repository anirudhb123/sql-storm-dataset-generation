WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT p.name) AS cast,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id
),
MovieRatings AS (
    SELECT 
        movie_id,
        AVG(r.rating) AS average_rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        ratings_table r ON mi.movie_id = r.movie_id
    WHERE 
        it.info = 'rating'
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.cast,
    md.companies,
    COALESCE(mr.average_rating, 0) AS average_rating
FROM 
    MovieDetails md
LEFT JOIN 
    MovieRatings mr ON md.movie_id = mr.movie_id
ORDER BY 
    md.production_year DESC, 
    mr.average_rating DESC
LIMIT 50;
