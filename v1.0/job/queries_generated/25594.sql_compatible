
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_members,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords,
        mn.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name mn ON mc.company_id = mn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year, mn.name, ct.kind
),
TitleSummary AS (
    SELECT
        movie_id,
        movie_title,
        SUM(CASE WHEN production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_count,
        SUM(CASE WHEN production_year >= 2000 AND production_year <= 2010 THEN 1 ELSE 0 END) AS from_2000_to_2010_count,
        SUM(CASE WHEN production_year > 2010 THEN 1 ELSE 0 END) AS post_2010_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, movie_title
)
SELECT
    ts.movie_title,
    md.production_year,
    ts.pre_2000_count,
    ts.from_2000_to_2010_count,
    ts.post_2010_count,
    md.cast_members,
    md.movie_keywords,
    md.company_name,
    md.company_type
FROM 
    TitleSummary ts
JOIN 
    MovieDetails md ON ts.movie_id = md.movie_id
ORDER BY 
    md.production_year DESC, ts.movie_title ASC;
